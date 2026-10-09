//go:build integration

// Package e2e 针对真实运行的后端（HTTP + WebSocket + PG + Redis）做端到端验证。
// 运行前提：后端已在 BASE（默认 http://localhost:8080）启动，PG/Redis 就绪。
//
//	go test -tags=integration ./test/... -run TestWS -v
package e2e

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"math/rand"
	"mime/multipart"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/coder/websocket"
)

func baseURL() string {
	if v := os.Getenv("E2E_BASE_URL"); v != "" {
		return v
	}
	return "http://localhost:8080"
}

func wsURL() string {
	if v := os.Getenv("E2E_WS_URL"); v != "" {
		return v
	}
	return "ws://localhost:8080/ws"
}

type envelope struct {
	Type    string          `json:"type"`
	Payload json.RawMessage `json:"payload"`
}

func doJSON(t *testing.T, method, path, token string, body any, out any) int {
	t.Helper()
	var rdr io.Reader
	if body != nil {
		b, _ := json.Marshal(body)
		rdr = bytes.NewReader(b)
	}
	req, err := http.NewRequest(method, baseURL()+path, rdr)
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)
	if out != nil && len(raw) > 0 {
		_ = json.Unmarshal(raw, out)
	}
	return resp.StatusCode
}

func register(t *testing.T, prefix string) (token, userID string) {
	t.Helper()
	name := prefix + randStr()
	var res struct {
		AccessToken string `json:"access_token"`
		User        struct {
			ID string `json:"id"`
		} `json:"user"`
	}
	code := doJSON(t, http.MethodPost, "/api/v1/auth/register", "", map[string]any{
		"username": name, "nickname": prefix, "password": "secret123",
	}, &res)
	if code != http.StatusCreated {
		t.Fatalf("register %s got %d", name, code)
	}
	return res.AccessToken, res.User.ID
}

func randStr() string {
	const letters = "abcdefghijklmnopqrstuvwxyz0123456789"
	b := make([]byte, 8)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}

// TestWSSendAndReceive 验证：A 发消息 → A 收到 msg_ack，B 收到 new_message。
func TestWSSendAndReceive(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	// 后端可达性预检
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}

	tokenA, _ := register(t, "wsA")
	tokenB, idB := register(t, "wsB")

	var conv struct {
		ConversationID string `json:"conversation_id"`
	}
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/direct", tokenA,
		map[string]any{"peer_id": idB}, &conv); code != http.StatusOK {
		t.Fatalf("create direct got %d", code)
	}

	dial := func(token string) *websocket.Conn {
		c, _, err := websocket.Dial(ctx, wsURL()+"?token="+token, nil)
		if err != nil {
			t.Fatalf("dial: %v", err)
		}
		return c
	}
	wsA, wsB := dial(tokenA), dial(tokenB)
	defer wsA.CloseNow()
	defer wsB.CloseNow()
	time.Sleep(500 * time.Millisecond) // 等两端在 Hub 完成注册，避免发送时对方尚未上线

	clientMsgID := "c-" + randStr()
	text := "hello-from-A-" + randStr()

	sendPayload, _ := json.Marshal(map[string]any{
		"client_msg_id":   clientMsgID,
		"conversation_id": conv.ConversationID,
		"content":         map[string]any{"type": 0, "text": text},
	})
	if err := wsA.Write(ctx, websocket.MessageText, marshalEnvelope(t, "send_message", sendPayload)); err != nil {
		t.Fatalf("wsA write: %v", err)
	}

	// A 应收到 msg_ack（匹配 client_msg_id 且带 server_msg_id/seq>0）
	ackOK := waitFor(t, wsA, func(p map[string]any) bool {
		return p["client_msg_id"] == clientMsgID && asInt64(p["seq"]) > 0
	}, 8*time.Second)
	if !ackOK {
		t.Fatal("未在超时内收到有效 msg_ack")
	}

	// B 应收到 new_message（同会话、同文本）
	recvOK := waitFor(t, wsB, func(p map[string]any) bool {
		if p["conversation_id"] != conv.ConversationID {
			return false
		}
		content, _ := p["content"].(map[string]any)
		return content != nil && content["text"] == text
	}, 8*time.Second)
	if !recvOK {
		t.Fatal("未在超时内收到 new_message")
	}
}

// TestWSSyncCatchUp 验证断线补拉：B 未在线时错过的消息，连接后通过 sync 拉回。
func TestWSSyncCatchUp(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}

	tokenA, _ := register(t, "scA")
	tokenB, idB := register(t, "scB")

	var conv struct {
		ConversationID string `json:"conversation_id"`
	}
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/direct", tokenA,
		map[string]any{"peer_id": idB}, &conv); code != http.StatusOK {
		t.Fatalf("create direct got %d", code)
	}

	// A 在线发送一条消息（此时 B 尚未连接，会错过实时推送）。
	wsA, _, err := websocket.Dial(ctx, wsURL()+"?token="+tokenA, nil)
	if err != nil {
		t.Fatal(err)
	}
	defer wsA.CloseNow()
	clientMsgID := "c-" + randStr()
	text := "missed-" + randStr()
	payload, _ := json.Marshal(map[string]any{
		"client_msg_id":   clientMsgID,
		"conversation_id": conv.ConversationID,
		"content":         map[string]any{"type": 0, "text": text},
	})
	if err := wsA.Write(ctx, websocket.MessageText, marshalEnvelope(t, "send_message", payload)); err != nil {
		t.Fatal(err)
	}
	if !waitFor(t, wsA, func(p map[string]any) bool {
		return p["client_msg_id"] == clientMsgID && asInt64(p["seq"]) > 0
	}, 8*time.Second) {
		t.Fatal("A 未收到 msg_ack")
	}

	// B 现在才连接，发 sync（last_seq=0），应通过 sync_result 拿到那条消息。
	wsB, _, err := websocket.Dial(ctx, wsURL()+"?token="+tokenB, nil)
	if err != nil {
		t.Fatal(err)
	}
	defer wsB.CloseNow()
	syncPayload, _ := json.Marshal(map[string]any{
		"conversation_id": conv.ConversationID,
		"last_seq":        0,
	})
	if err := wsB.Write(ctx, websocket.MessageText, marshalEnvelope(t, "sync", syncPayload)); err != nil {
		t.Fatal(err)
	}

	deadline := time.Now().Add(8 * time.Second)
	for time.Now().Before(deadline) {
		rctx, rcancel := context.WithTimeout(context.Background(), time.Until(deadline))
		_, data, rerr := wsB.Read(rctx)
		rcancel()
		if rerr != nil {
			break
		}
		var env envelope
		if json.Unmarshal(data, &env) != nil || env.Type != "sync_result" {
			continue
		}
		var res struct {
			Messages []map[string]any `json:"messages"`
		}
		if json.Unmarshal(env.Payload, &res) != nil {
			continue
		}
		for _, m := range res.Messages {
			content, _ := m["content"].(map[string]any)
			if content != nil && content["text"] == text {
				return // 补拉成功
			}
		}
	}
	t.Fatal("sync_result 未包含错过的消息")
}

// TestMarkReadAndUnread 验证：B 收到未读计数，mark_read 后清零。
func TestMarkReadAndUnread(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 25*time.Second)
	defer cancel()
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}

	tokenA, _ := register(t, "ruA")
	tokenB, idB := register(t, "ruB")

	var conv struct {
		ConversationID string `json:"conversation_id"`
	}
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/direct", tokenA,
		map[string]any{"peer_id": idB}, &conv); code != http.StatusOK {
		t.Fatalf("create direct got %d", code)
	}

	// A 通过 WS 发 2 条消息。
	wsA, _, err := websocket.Dial(ctx, wsURL()+"?token="+tokenA, nil)
	if err != nil {
		t.Fatal(err)
	}
	defer wsA.CloseNow()
	for i := 0; i < 2; i++ {
		cid := fmt.Sprintf("ru-%d-%s", i, randStr())
		payload, _ := json.Marshal(map[string]any{
			"client_msg_id":   cid,
			"conversation_id": conv.ConversationID,
			"content":         map[string]any{"type": 0, "text": fmt.Sprintf("m%d", i)},
		})
		if err := wsA.Write(ctx, websocket.MessageText, marshalEnvelope(t, "send_message", payload)); err != nil {
			t.Fatal(err)
		}
		if !waitFor(t, wsA, func(p map[string]any) bool {
			return p["client_msg_id"] == cid && asInt64(p["seq"]) > 0
		}, 8*time.Second) {
			t.Fatalf("A 未收到第 %d 条的 msg_ack", i)
		}
	}

	if got := fetchUnread(t, tokenB, conv.ConversationID); got < 2 {
		t.Fatalf("期望未读>=2，实际 %d", got)
	}

	// B 连 WS 上报已读（max_seq 足够大覆盖已有消息）。
	wsB, _, err := websocket.Dial(ctx, wsURL()+"?token="+tokenB, nil)
	if err != nil {
		t.Fatal(err)
	}
	defer wsB.CloseNow()
	mr, _ := json.Marshal(map[string]any{
		"conversation_id": conv.ConversationID,
		"max_seq":         1000000,
	})
	if err := wsB.Write(ctx, websocket.MessageText, marshalEnvelope(t, "mark_read", mr)); err != nil {
		t.Fatal(err)
	}
	// 给服务端一点处理时间（mark_read 无下行回执）。
	time.Sleep(500 * time.Millisecond)

	if got := fetchUnread(t, tokenB, conv.ConversationID); got != 0 {
		t.Fatalf("已读后期望未读=0，实际 %d", got)
	}
}

func fetchUnread(t *testing.T, token, convID string) int {
	t.Helper()
	var res struct {
		Conversations []struct {
			ID     string `json:"id"`
			Unread int    `json:"unread"`
		} `json:"conversations"`
	}
	if code := doJSON(t, http.MethodGet, "/api/v1/conversations", token, nil, &res); code != http.StatusOK {
		t.Fatalf("list conversations got %d", code)
	}
	for _, c := range res.Conversations {
		if c.ID == convID {
			return c.Unread
		}
	}
	t.Fatalf("会话 %s 不在列表中", convID)
	return -1
}

// TestWSTyping 验证：A 的 typing 事件被转发给同会话在线的 B。
func TestWSTyping(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}

	tokenA, idA := register(t, "tpA")
	tokenB, idB := register(t, "tpB")

	var conv struct {
		ConversationID string `json:"conversation_id"`
	}
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/direct", tokenA,
		map[string]any{"peer_id": idB}, &conv); code != http.StatusOK {
		t.Fatalf("create direct got %d", code)
	}

	wsA, _, err := websocket.Dial(ctx, wsURL()+"?token="+tokenA, nil)
	if err != nil {
		t.Fatal(err)
	}
	defer wsA.CloseNow()
	wsB, _, err := websocket.Dial(ctx, wsURL()+"?token="+tokenB, nil)
	if err != nil {
		t.Fatal(err)
	}
	defer wsB.CloseNow()
	time.Sleep(300 * time.Millisecond) // 等 B 在 Hub 注册上线

	tp, _ := json.Marshal(map[string]any{
		"conversation_id": conv.ConversationID,
		"typing":          true,
	})
	if err := wsA.Write(ctx, websocket.MessageText, marshalEnvelope(t, "typing", tp)); err != nil {
		t.Fatal(err)
	}

	deadline := time.Now().Add(6 * time.Second)
	for time.Now().Before(deadline) {
		rctx, rcancel := context.WithTimeout(context.Background(), time.Until(deadline))
		_, data, rerr := wsB.Read(rctx)
		rcancel()
		if rerr != nil {
			break
		}
		var env envelope
		if json.Unmarshal(data, &env) != nil || env.Type != "typing" {
			continue
		}
		var p map[string]any
		if json.Unmarshal(env.Payload, &p) != nil {
			continue
		}
		if p["from_user_id"] == idA && p["conversation_id"] == conv.ConversationID && p["typing"] == true {
			return
		}
	}
	t.Fatal("B 未收到转发的 typing 事件")
}

// TestConversationDetailAndGroup 验证 GET /conversations/:id 详情与建群。
func TestConversationDetailAndGroup(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}

	tokenA, _ := register(t, "dtA")
	_, idB := register(t, "dtB")
	_, idC := register(t, "dtC")

	var direct struct {
		ConversationID string `json:"conversation_id"`
	}
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/direct", tokenA,
		map[string]any{"peer_id": idB}, &direct); code != http.StatusOK {
		t.Fatalf("create direct got %d", code)
	}

	var dd struct {
		Conversation struct {
			ID   string `json:"id"`
			Type int    `json:"type"`
		} `json:"conversation"`
		Members []struct {
			UserID string `json:"user_id"`
		} `json:"members"`
	}
	if code := doJSON(t, http.MethodGet, "/api/v1/conversations/"+direct.ConversationID, tokenA, nil, &dd); code != http.StatusOK {
		t.Fatalf("detail got %d", code)
	}
	if len(dd.Members) != 2 {
		t.Fatalf("单聊详情期望 2 成员，实际 %d", len(dd.Members))
	}

	var grp struct {
		ConversationID string `json:"conversation_id"`
	}
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/group", tokenA,
		map[string]any{"name": "测试群", "member_ids": []string{idB, idC}}, &grp); code != http.StatusOK {
		t.Fatalf("create group got %d", code)
	}

	var gd struct {
		Conversation struct {
			Type int `json:"type"`
		} `json:"conversation"`
		Members []struct {
			UserID string `json:"user_id"`
		} `json:"members"`
	}
	if code := doJSON(t, http.MethodGet, "/api/v1/conversations/"+grp.ConversationID, tokenA, nil, &gd); code != http.StatusOK {
		t.Fatalf("group detail got %d", code)
	}
	if gd.Conversation.Type != 1 || len(gd.Members) != 3 {
		t.Fatalf("群聊详情不对: type=%d members=%d", gd.Conversation.Type, len(gd.Members))
	}
}

// fetchMessages 拉取某会话历史（GET /conversations/:id/messages），返回 seq 升序列表。
func fetchMessages(t *testing.T, token, convID string, beforeSeq int64, limit int) []int64 {
	t.Helper()
	q := fmt.Sprintf("/api/v1/conversations/%s/messages?limit=%d", convID, limit)
	if beforeSeq > 0 {
		q += fmt.Sprintf("&before_seq=%d", beforeSeq)
	}
	var res struct {
		Messages []struct {
			Seq     int64 `json:"seq"`
			Content struct {
				Text string `json:"text"`
			} `json:"content"`
		} `json:"messages"`
	}
	if code := doJSON(t, http.MethodGet, q, token, nil, &res); code != http.StatusOK {
		t.Fatalf("history got %d", code)
	}
	out := make([]int64, 0, len(res.Messages))
	for _, m := range res.Messages {
		out = append(out, m.Seq)
	}
	return out
}

// TestHistoryPagination 验证：上滑分页返回更旧的消息，且不重叠、时间正序。
func TestHistoryPagination(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 25*time.Second)
	defer cancel()
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}

	tokenA, _ := register(t, "hpA")
	_, idB := register(t, "hpB")

	var conv struct {
		ConversationID string `json:"conversation_id"`
	}
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/direct", tokenA,
		map[string]any{"peer_id": idB}, &conv); code != http.StatusOK {
		t.Fatalf("create direct got %d", code)
	}

	wsA, _, err := websocket.Dial(ctx, wsURL()+"?token="+tokenA, nil)
	if err != nil {
		t.Fatal(err)
	}
	defer wsA.CloseNow()
	const total = 5
	for i := 0; i < total; i++ {
		cid := fmt.Sprintf("hp-%d-%s", i, randStr())
		payload, _ := json.Marshal(map[string]any{
			"client_msg_id":   cid,
			"conversation_id": conv.ConversationID,
			"content":         map[string]any{"type": 0, "text": fmt.Sprintf("m%d", i)},
		})
		if err := wsA.Write(ctx, websocket.MessageText, marshalEnvelope(t, "send_message", payload)); err != nil {
			t.Fatal(err)
		}
		if !waitFor(t, wsA, func(p map[string]any) bool {
			return p["client_msg_id"] == cid && asInt64(p["seq"]) > 0
		}, 8*time.Second) {
			t.Fatalf("A 未收到第 %d 条的 msg_ack", i)
		}
	}

	// 第一页：最近 2 条 -> seq [4,5]（正序）。
	page1 := fetchMessages(t, tokenA, conv.ConversationID, 0, 2)
	if len(page1) != 2 || page1[0] >= page1[1] {
		t.Fatalf("page1 期望 2 条正序, 实际 %v", page1)
	}
	// 第二页：before_seq=page1 最小 seq -> 更旧的 [2,3]，且与 page1 无重叠。
	page2 := fetchMessages(t, tokenA, conv.ConversationID, page1[0], 2)
	if len(page2) != 2 || page2[0] >= page2[1] {
		t.Fatalf("page2 期望 2 条正序, 实际 %v", page2)
	}
	if page2[1] >= page1[0] {
		t.Fatalf("分页重叠/错序: page2=%v page1=%v", page2, page1)
	}
}

// TestConversationOrdering 验证：会话列表按最近消息时间倒序（新消息的会话置顶）。
func TestConversationOrdering(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 25*time.Second)
	defer cancel()
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}

	tokenA, _ := register(t, "ordA")
	_, idB := register(t, "ordB")
	_, idC := register(t, "ordC")

	mk := func(peer string) string {
		var c struct {
			ConversationID string `json:"conversation_id"`
		}
		if code := doJSON(t, http.MethodPost, "/api/v1/conversations/direct", tokenA,
			map[string]any{"peer_id": peer}, &c); code != http.StatusOK {
			t.Fatalf("create direct got %d", code)
		}
		return c.ConversationID
	}
	convB := mk(idB)
	convC := mk(idC)

	wsA, _, err := websocket.Dial(ctx, wsURL()+"?token="+tokenA, nil)
	if err != nil {
		t.Fatal(err)
	}
	defer wsA.CloseNow()

	send := func(convID, tag string) {
		cid := tag + "-" + randStr()
		payload, _ := json.Marshal(map[string]any{
			"client_msg_id":   cid,
			"conversation_id": convID,
			"content":         map[string]any{"type": 0, "text": tag},
		})
		if err := wsA.Write(ctx, websocket.MessageText, marshalEnvelope(t, "send_message", payload)); err != nil {
			t.Fatal(err)
		}
		if !waitFor(t, wsA, func(p map[string]any) bool {
			return p["client_msg_id"] == cid && asInt64(p["seq"]) > 0
		}, 8*time.Second) {
			t.Fatalf("未收到 %s 的 msg_ack", tag)
		}
	}

	send(convB, "first")
	time.Sleep(1200 * time.Millisecond) // 拉开 last_msg_at，确保排序可判
	send(convC, "second")

	var res struct {
		Conversations []struct {
			ID string `json:"id"`
		} `json:"conversations"`
	}
	if code := doJSON(t, http.MethodGet, "/api/v1/conversations", tokenA, nil, &res); code != http.StatusOK {
		t.Fatalf("list got %d", code)
	}
	if len(res.Conversations) < 2 {
		t.Fatalf("期望至少 2 个会话, 实际 %d", len(res.Conversations))
	}
	if res.Conversations[0].ID != convC {
		t.Fatalf("最近活动的会话应置顶: got %s want %s", res.Conversations[0].ID, convC)
	}
}

// ---- Phase B: 群管理与会话偏好 ----

type convRow struct {
	ID     string `json:"id"`
	Pinned bool   `json:"pinned"`
	Muted  bool   `json:"muted"`
	Unread int    `json:"unread"`
}

func listConvs(t *testing.T, token string) []convRow {
	t.Helper()
	var res struct {
		Conversations []convRow `json:"conversations"`
	}
	if code := doJSON(t, http.MethodGet, "/api/v1/conversations", token, nil, &res); code != http.StatusOK {
		t.Fatalf("list got %d", code)
	}
	return res.Conversations
}

func convIndex(list []convRow, id string) int {
	for i, r := range list {
		if r.ID == id {
			return i
		}
	}
	return -1
}

func createDirect(t *testing.T, token, peer string) string {
	t.Helper()
	var c struct {
		ConversationID string `json:"conversation_id"`
	}
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/direct", token,
		map[string]any{"peer_id": peer}, &c); code != http.StatusOK {
		t.Fatalf("create direct got %d", code)
	}
	return c.ConversationID
}

func detailNameCount(t *testing.T, token, convID string) (string, int) {
	t.Helper()
	var d struct {
		Conversation struct {
			Name string `json:"name"`
		} `json:"conversation"`
		Members []struct {
			UserID string `json:"user_id"`
		} `json:"members"`
	}
	if code := doJSON(t, http.MethodGet, "/api/v1/conversations/"+convID, token, nil, &d); code != http.StatusOK {
		t.Fatalf("detail got %d", code)
	}
	return d.Conversation.Name, len(d.Members)
}

// sendText 用 token 连 WS 向 convID 发一条文本并等 ack（返回时服务端已同步处理）。
func sendText(t *testing.T, token, convID, text string) {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	ws, _, err := websocket.Dial(ctx, wsURL()+"?token="+token, nil)
	if err != nil {
		t.Fatal(err)
	}
	defer ws.CloseNow()
	cid := "pf-" + randStr()
	payload, _ := json.Marshal(map[string]any{
		"client_msg_id":   cid,
		"conversation_id": convID,
		"content":         map[string]any{"type": 0, "text": text},
	})
	if err := ws.Write(ctx, websocket.MessageText, marshalEnvelope(t, "send_message", payload)); err != nil {
		t.Fatal(err)
	}
	if !waitFor(t, ws, func(p map[string]any) bool {
		return p["client_msg_id"] == cid && asInt64(p["seq"]) > 0
	}, 8*time.Second) {
		t.Fatalf("send_text 未收到 ack conv=%s", convID)
	}
}

// TestGroupManagement 验证：改名(仅群主)/加成员/踢成员/退群。
func TestGroupManagement(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	tokenA, idA := register(t, "gmA")
	tokenB, idB := register(t, "gmB")
	tokenC, idC := register(t, "gmC")
	_, idD := register(t, "gmD")
	_ = idA

	var g struct {
		ConversationID string `json:"conversation_id"`
	}
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/group", tokenA,
		map[string]any{"name": "初始群", "member_ids": []string{idB, idC}}, &g); code != http.StatusOK {
		t.Fatalf("create group got %d", code)
	}
	conv := g.ConversationID
	if _, n := detailNameCount(t, tokenA, conv); n != 3 {
		t.Fatalf("建群后期望 3 成员，实际 %d", n)
	}

	// owner 改名
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/"+conv+"/rename", tokenA,
		map[string]any{"name": "新群名"}, nil); code != http.StatusOK {
		t.Fatalf("rename got %d", code)
	}
	if nm, _ := detailNameCount(t, tokenA, conv); nm != "新群名" {
		t.Fatalf("改名未生效: %q", nm)
	}
	// 非群主改名 -> 403
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/"+conv+"/rename", tokenB,
		map[string]any{"name": "x"}, nil); code != http.StatusForbidden {
		t.Fatalf("非群主改名期望 403，实际 %d", code)
	}
	// 加 D
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/"+conv+"/members/add", tokenA,
		map[string]any{"user_ids": []string{idD}}, nil); code != http.StatusOK {
		t.Fatalf("add member got %d", code)
	}
	if _, n := detailNameCount(t, tokenA, conv); n != 4 {
		t.Fatalf("加人后期望 4 成员，实际 %d", n)
	}
	// 踢 B
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/"+conv+"/members/remove", tokenA,
		map[string]any{"user_id": idB}, nil); code != http.StatusOK {
		t.Fatalf("remove member got %d", code)
	}
	if _, n := detailNameCount(t, tokenA, conv); n != 3 {
		t.Fatalf("踢人后期望 3 成员，实际 %d", n)
	}
	// C 退群
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/"+conv+"/leave", tokenC, nil, nil); code != http.StatusOK {
		t.Fatalf("leave got %d", code)
	}
	if _, n := detailNameCount(t, tokenA, conv); n != 2 {
		t.Fatalf("C 退群后期望 2 成员，实际 %d", n)
	}
}

// TestConversationPrefs 验证：置顶优先排序、免打扰标记、软删除与来新消息自动解除。
func TestConversationPrefs(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	tokenA, _ := register(t, "pfA")
	tokenB, idB := register(t, "pfB")
	_, idC := register(t, "pfC")

	convB := createDirect(t, tokenA, idB)
	convC := createDirect(t, tokenA, idC)

	// 置顶 convB
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/"+convB+"/pin", tokenA,
		map[string]any{"pinned": true}, nil); code != http.StatusOK {
		t.Fatalf("pin got %d", code)
	}
	// 使 convC 成为最新（发一条）
	sendText(t, tokenA, convC, "newest")

	list := listConvs(t, tokenA)
	iB, iC := convIndex(list, convB), convIndex(list, convC)
	if iB < 0 || iC < 0 {
		t.Fatalf("列表缺会话 B=%d C=%d", iB, iC)
	}
	if iB > iC {
		t.Fatalf("置顶会话应排在更新会话之前: B=%d C=%d", iB, iC)
	}

	// 免打扰 convC
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/"+convC+"/mute", tokenA,
		map[string]any{"muted": true}, nil); code != http.StatusOK {
		t.Fatalf("mute got %d", code)
	}
	if r := listConvs(t, tokenA); convIndex(r, convC) >= 0 && !r[convIndex(r, convC)].Muted {
		t.Fatalf("convC 应标记为已免打扰")
	}

	// 软删除 convB -> 从列表消失
	if code := doJSON(t, http.MethodDelete, "/api/v1/conversations/"+convB, tokenA, nil, nil); code != http.StatusOK {
		t.Fatalf("hide got %d", code)
	}
	if convIndex(listConvs(t, tokenA), convB) >= 0 {
		t.Fatalf("隐藏后 convB 不应在列表")
	}

	// 对端 B 发新消息 -> 解除隐藏
	sendText(t, tokenB, convB, "wake")
	if convIndex(listConvs(t, tokenA), convB) < 0 {
		t.Fatalf("收到新消息后 convB 应重新出现在列表")
	}
}

// TestMediaUploadAndFetch 验证：上传媒体到对象存储并代理下载。
// 未配 MinIO/对象存储时（上传返回 5xx）自动 skip。
func TestMediaUploadAndFetch(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	token, _ := register(t, "mdU")

	payload := []byte("\x89PNG\r\n\x1a\n fake-media-bytes")
	var buf bytes.Buffer
	w := multipart.NewWriter(&buf)
	part, err := w.CreateFormFile("file", "test.png")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := part.Write(payload); err != nil {
		t.Fatal(err)
	}
	w.Close()

	req, _ := http.NewRequest(http.MethodPost, baseURL()+"/api/v1/media", &buf)
	req.Header.Set("Content-Type", w.FormDataContentType())
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)

	if resp.StatusCode >= 500 {
		t.Skipf("对象存储不可用（上传 %d），跳过媒体测试: %s", resp.StatusCode, string(body))
	}
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("上传期望 200，实际 %d: %s", resp.StatusCode, string(body))
	}

	var up struct {
		MediaID string `json:"media_id"`
		URL     string `json:"url"`
		Mime    string `json:"mime"`
	}
	if err := json.Unmarshal(body, &up); err != nil {
		t.Fatalf("解析上传响应: %v (%s)", err, string(body))
	}
	if up.MediaID == "" || up.URL == "" {
		t.Fatalf("上传响应缺字段: %+v", up)
	}

	// 公开下载（无 Authorization 头），内容应一致。
	dl, err := http.Get(up.URL)
	if err != nil {
		t.Fatalf("下载请求: %v", err)
	}
	defer dl.Body.Close()
	got, _ := io.ReadAll(dl.Body)
	if dl.StatusCode != http.StatusOK {
		t.Fatalf("下载期望 200，实际 %d", dl.StatusCode)
	}
	if !bytes.Equal(got, payload) {
		t.Fatalf("下载内容不一致: got %d bytes want %d", len(got), len(payload))
	}
}

func marshalEnvelope(t *testing.T, typ string, payload json.RawMessage) []byte {
	t.Helper()
	b, err := json.Marshal(envelope{Type: typ, Payload: payload})
	if err != nil {
		t.Fatal(err)
	}
	return b
}

// waitFor 读取 ws 下行帧直到谓词命中或超时。
func waitFor(t *testing.T, ws *websocket.Conn, pred func(map[string]any) bool, timeout time.Duration) bool {
	t.Helper()
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		ctx, cancel := context.WithTimeout(context.Background(), time.Until(deadline))
		typ, data, err := ws.Read(ctx)
		cancel()
		if err != nil {
			return false
		}
		if typ != websocket.MessageText && typ != websocket.MessageBinary {
			continue
		}
		var env envelope
		if err := json.Unmarshal(data, &env); err != nil {
			continue
		}
		var p map[string]any
		if err := json.Unmarshal(env.Payload, &p); err != nil {
			continue
		}
		if pred(p) {
			return true
		}
	}
	return false
}

func asInt64(v any) int64 {
	switch x := v.(type) {
	case float64:
		return int64(x)
	case int64:
		return x
	default:
		return 0
	}
}

// awaitPayload 读取下行帧直到谓词命中，返回命中的 payload（超时返回 nil）。
func awaitPayload(t *testing.T, ws *websocket.Conn, pred func(map[string]any) bool, timeout time.Duration) map[string]any {
	t.Helper()
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		ctx, cancel := context.WithTimeout(context.Background(), time.Until(deadline))
		_, data, err := ws.Read(ctx)
		cancel()
		if err != nil {
			return nil
		}
		var env envelope
		if err := json.Unmarshal(data, &env); err != nil {
			continue
		}
		var p map[string]any
		if err := json.Unmarshal(env.Payload, &p); err != nil {
			continue
		}
		if pred(p) {
			return p
		}
	}
	return nil
}

func wsDial(t *testing.T, ctx context.Context, token string) *websocket.Conn {
	t.Helper()
	c, _, err := websocket.Dial(ctx, wsURL()+"?token="+token, nil)
	if err != nil {
		t.Fatal(err)
	}
	return c
}

func sendEnvelope(t *testing.T, ws *websocket.Conn, typ string, payload map[string]any) {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	raw, _ := json.Marshal(payload)
	if err := ws.Write(ctx, websocket.MessageText, marshalEnvelope(t, typ, raw)); err != nil {
		t.Fatal(err)
	}
}

// sendContentVia 通过已连接的 ws 发送一条消息并等待 ack，返回 server_msg_id。
func sendContentVia(t *testing.T, ws *websocket.Conn, convID string, content map[string]any) string {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	cid := "c-" + randStr()
	payload, _ := json.Marshal(map[string]any{
		"client_msg_id":   cid,
		"conversation_id": convID,
		"content":         content,
	})
	if err := ws.Write(ctx, websocket.MessageText, marshalEnvelope(t, "send_message", payload)); err != nil {
		t.Fatal(err)
	}
	ack := awaitPayload(t, ws, func(p map[string]any) bool {
		return p["client_msg_id"] == cid && asInt64(p["seq"]) > 0
	}, 8*time.Second)
	if ack == nil {
		t.Fatal("send 未收到 ack")
	}
	sid, _ := ack["server_msg_id"].(string)
	if sid == "" {
		t.Fatal("ack 缺 server_msg_id")
	}
	return sid
}

// TestMessageRecallAndEdit 验证：本人撤回/编辑→服务端落库并向成员广播 message_update；越权被拒。
func TestMessageRecallAndEdit(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	tokenA, _ := register(t, "rcA")
	tokenB, idB := register(t, "rcB")
	conv := createDirect(t, tokenA, idB)

	wsA, wsB := wsDial(t, ctx, tokenA), wsDial(t, ctx, tokenB)
	defer wsA.CloseNow()
	defer wsB.CloseNow()
	time.Sleep(500 * time.Millisecond)

	// 撤回
	sid1 := sendContentVia(t, wsA, conv, map[string]any{"type": 0, "text": "to-recall-" + randStr()})
	sendEnvelope(t, wsA, "recall_message", map[string]any{"conversation_id": conv, "server_msg_id": sid1})
	upA := awaitPayload(t, wsA, func(p map[string]any) bool {
		return p["server_msg_id"] == sid1 && p["recalled"] == true
	}, 8*time.Second)
	if upA == nil {
		t.Fatal("A 未收到撤回的 message_update")
	}
	if tc, ok := upA["content"].(map[string]any)["text"].(string); ok && tc != "" {
		t.Fatalf("撤回后正文未清空: %v", tc)
	}
	upB := awaitPayload(t, wsB, func(p map[string]any) bool {
		return p["server_msg_id"] == sid1 && p["recalled"] == true
	}, 8*time.Second)
	if upB == nil {
		t.Fatal("B 未收到撤回的 message_update")
	}

	// 编辑
	sid2 := sendContentVia(t, wsA, conv, map[string]any{"type": 0, "text": "orig-" + randStr()})
	edited := "edited-" + randStr()
	sendEnvelope(t, wsA, "edit_message", map[string]any{"conversation_id": conv, "server_msg_id": sid2, "text": edited})
	upEdit := awaitPayload(t, wsB, func(p map[string]any) bool {
		if p["server_msg_id"] != sid2 {
			return false
		}
		c, _ := p["content"].(map[string]any)
		return c["text"] == edited
	}, 8*time.Second)
	if upEdit == nil {
		t.Fatal("B 未收到编辑的 message_update")
	}

	// 越权：B 撤回 A 的消息应被拒（收到 error 帧）
	sid3 := sendContentVia(t, wsA, conv, map[string]any{"type": 0, "text": "not-yours-" + randStr()})
	sendEnvelope(t, wsB, "recall_message", map[string]any{"conversation_id": conv, "server_msg_id": sid3})
	if errFrame := awaitPayload(t, wsB, func(p map[string]any) bool {
		return p["message"] != nil
	}, 6*time.Second); errFrame == nil {
		t.Fatal("B 越权撤回未收到错误回执")
	}
	_ = tokenB
}

// TestMessageMentionsAndReply 验证：mentions 与 reply_to 随 content JSONB 透传与落库。
func TestMessageMentionsAndReply(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	tokenA, idA := register(t, "mrA")
	tokenB, idB := register(t, "mrB")
	conv := createDirect(t, tokenA, idB)
	wsA, wsB := wsDial(t, ctx, tokenA), wsDial(t, ctx, tokenB)
	defer wsA.CloseNow()
	defer wsB.CloseNow()
	time.Sleep(500 * time.Millisecond)

	quote := "quoted-" + randStr()
	sidQuote := sendContentVia(t, wsA, conv, map[string]any{"type": 0, "text": quote})

	uniq := "mention-" + randStr()
	sid := sendContentVia(t, wsA, conv, map[string]any{
		"type":     0,
		"text":     "hi @B " + uniq,
		"mentions": []string{idB},
		"reply_to": map[string]any{"msg_id": sidQuote, "sender_id": idA, "text": quote},
	})

	got := awaitPayload(t, wsB, func(p map[string]any) bool {
		return p["server_msg_id"] == sid
	}, 8*time.Second)
	if got == nil {
		t.Fatal("B 未收到该消息")
	}
	c, _ := got["content"].(map[string]any)
	if mentions, _ := c["mentions"].([]any); len(mentions) != 1 || mentions[0] != idB {
		t.Fatalf("mentions 未透传: %v", c["mentions"])
	}
	if rt, _ := c["reply_to"].(map[string]any); rt == nil || rt["msg_id"] != sidQuote {
		t.Fatalf("reply_to 未透传: %v", c["reply_to"])
	}

	// 落库校验
	var res struct {
		Messages []struct {
			ID      string `json:"server_msg_id"`
			Content struct {
				Mentions []string `json:"mentions"`
				ReplyTo  *struct {
					MsgID string `json:"msg_id"`
				} `json:"reply_to"`
			} `json:"content"`
		} `json:"messages"`
	}
	if code := doJSON(t, http.MethodGet, "/api/v1/conversations/"+conv+"/messages?limit=50", tokenA, nil, &res); code != http.StatusOK {
		t.Fatalf("history got %d", code)
	}
	found := false
	for _, m := range res.Messages {
		if m.ID != sid {
			continue
		}
		found = true
		if len(m.Content.Mentions) != 1 || m.Content.Mentions[0] != idB {
			t.Fatalf("库中 mentions 丢失: %v", m.Content.Mentions)
		}
		if m.Content.ReplyTo == nil || m.Content.ReplyTo.MsgID != sidQuote {
			t.Fatalf("库中 reply_to 丢失: %+v", m.Content.ReplyTo)
		}
	}
	if !found {
		t.Fatal("历史未返回该消息")
	}
}

// TestMessageSearch 验证：会话内按关键字 ILIKE 检索文本消息。
func TestMessageSearch(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	tokenA, _ := register(t, "scA")
	_, idB := register(t, "scB")
	conv := createDirect(t, tokenA, idB)

	needle := "tiger-" + randStr()
	sendText(t, tokenA, conv, "decoy-"+randStr())
	sendText(t, tokenA, conv, needle)
	sendText(t, tokenA, conv, "another-"+randStr())

	var res struct {
		Messages []struct {
			Content struct {
				Text string `json:"text"`
			} `json:"content"`
		} `json:"messages"`
	}
	q := "/api/v1/conversations/" + conv + "/messages/search?q=tiger"
	if code := doJSON(t, http.MethodGet, q, tokenA, nil, &res); code != http.StatusOK {
		t.Fatalf("search got %d", code)
	}
	if len(res.Messages) == 0 {
		t.Fatal("搜索未命中已知消息")
	}
	hit := false
	for _, m := range res.Messages {
		if !strings.Contains(m.Content.Text, "tiger") {
			t.Fatalf("搜索返回不匹配项: %q", m.Content.Text)
		}
		if m.Content.Text == needle {
			hit = true
		}
	}
	if !hit {
		t.Fatal("未搜到目标 needle")
	}
}

// uploadMedia 上传一段字节到对象存储，返回服务端代理下载 url。
func uploadMedia(t *testing.T, token string, data []byte, filename string) string {
	t.Helper()
	var buf bytes.Buffer
	w := multipart.NewWriter(&buf)
	part, err := w.CreateFormFile("file", filename)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := part.Write(data); err != nil {
		t.Fatal(err)
	}
	w.Close()
	req, _ := http.NewRequest(http.MethodPost, baseURL()+"/api/v1/media", &buf)
	req.Header.Set("Content-Type", w.FormDataContentType())
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode >= 500 {
		t.Skipf("对象存储不可用(%d)，跳过语音测试", resp.StatusCode)
	}
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("上传 got %d: %s", resp.StatusCode, body)
	}
	var up struct {
		URL string `json:"url"`
	}
	_ = json.Unmarshal(body, &up)
	return up.URL
}

// TestVoiceMessageFlow 验证：上传音频→发 voice 消息(含时长)→成员实时收到→代理下载字节一致。
func TestVoiceMessageFlow(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	tokenA, _ := register(t, "vcA")
	tokenB, idB := register(t, "vcB")
	conv := createDirect(t, tokenA, idB)

	audio := []byte("FAKE-AUDIO-BYTES-" + randStr())
	url := uploadMedia(t, tokenA, audio, "voice.m4a")
	if url == "" {
		t.Fatal("媒体上传未返回 url")
	}

	wsA, wsB := wsDial(t, ctx, tokenA), wsDial(t, ctx, tokenB)
	defer wsA.CloseNow()
	defer wsB.CloseNow()
	time.Sleep(300 * time.Millisecond)

	sid := sendContentVia(t, wsA, conv, map[string]any{
		"type": 3, "media_url": url, "size": len(audio), "duration": 7,
	})
	got := awaitPayload(t, wsB, func(p map[string]any) bool {
		return p["server_msg_id"] == sid
	}, 8*time.Second)
	if got == nil {
		t.Fatal("B 未收到语音消息")
	}
	c, _ := got["content"].(map[string]any)
	if asInt64(c["type"]) != 3 {
		t.Fatalf("type 期望 3，got %v", c["type"])
	}
	if c["media_url"] != url {
		t.Fatalf("media_url 不符: %v", c["media_url"])
	}
	if asInt64(c["duration"]) != 7 {
		t.Fatalf("duration 期望 7，got %v", c["duration"])
	}

	// 代理下载校验字节一致
	resp, err := http.Get(url)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	dl, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK || !bytes.Equal(dl, audio) {
		t.Fatalf("语音下载校验失败 status=%d len=%d", resp.StatusCode, len(dl))
	}
}

// TestReadReceipt 验证：B 已读后，A 收到 msg_read 广播（供发送方展示已读）。
func TestReadReceipt(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	tokenA, _ := register(t, "rrA")
	tokenB, idB := register(t, "rrB")
	conv := createDirect(t, tokenA, idB)

	wsA, wsB := wsDial(t, ctx, tokenA), wsDial(t, ctx, tokenB)
	defer wsA.CloseNow()
	defer wsB.CloseNow()
	time.Sleep(500 * time.Millisecond)

	sid := sendContentVia(t, wsA, conv, map[string]any{"type": 0, "text": "read-me-" + randStr()})
	got := awaitPayload(t, wsB, func(p map[string]any) bool {
		return p["server_msg_id"] == sid
	}, 8*time.Second)
	if got == nil {
		t.Fatal("B 未收到消息")
	}
	seq := asInt64(got["seq"])

	sendEnvelope(t, wsB, "mark_read", map[string]any{"conversation_id": conv, "max_seq": seq})

	rd := awaitPayload(t, wsA, func(p map[string]any) bool {
		return p["user_id"] == idB && asInt64(p["max_seq"]) >= seq &&
			p["conversation_id"] == conv
	}, 8*time.Second)
	if rd == nil {
		t.Fatal("A 未收到已读回执 msg_read")
	}
}

// TestConversationPreview 验证：会话列表返回最后消息预览、@我标记与时间。
func TestConversationPreview(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	tokenA, idA := register(t, "pvA")
	tokenB, idB := register(t, "pvB")
	conv := createDirect(t, tokenA, idB)

	// B 发一条 @A 的文本消息（作为会话最后一条）
	wsB := wsDial(t, ctx, tokenB)
	defer wsB.CloseNow()
	time.Sleep(300 * time.Millisecond)
	body := "hello-preview-" + randStr()
	sendContentVia(t, wsB, conv, map[string]any{
		"type": 0, "text": body, "mentions": []string{idA},
	})

	var res struct {
		Conversations []struct {
			ID      string  `json:"id"`
			Preview string  `json:"preview"`
			Mention bool    `json:"mention_me"`
			LastAt  *string `json:"last_at"`
		} `json:"conversations"`
	}
	if code := doJSON(t, http.MethodGet, "/api/v1/conversations", tokenA, nil, &res); code != http.StatusOK {
		t.Fatalf("list got %d", code)
	}
	var found bool
	for _, c := range res.Conversations {
		if c.ID != conv {
			continue
		}
		found = true
		if c.Preview != body {
			t.Fatalf("preview 不符: got %q want %q", c.Preview, body)
		}
		if !c.Mention {
			t.Fatal("mention_me 应为 true")
		}
		if c.LastAt == nil {
			t.Fatal("last_at 为空")
		}
	}
	if !found {
		t.Fatal("列表未含该会话")
	}
}

// TestLocalDeleteForViewer 验证：本地删除仅影响自己的历史视图，他人不受影响。
func TestLocalDeleteForViewer(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	tokenA, _ := register(t, "delA")
	tokenB, idB := register(t, "delB")
	conv := createDirect(t, tokenA, idB)

	wsA := wsDial(t, ctx, tokenA)
	defer wsA.CloseNow()
	time.Sleep(300 * time.Millisecond)

	sid1 := sendContentVia(t, wsA, conv, map[string]any{"type": 0, "text": "d1-" + randStr()})
	sendContentVia(t, wsA, conv, map[string]any{"type": 0, "text": "d2-" + randStr()})
	sendContentVia(t, wsA, conv, map[string]any{"type": 0, "text": "d3-" + randStr()})

	if before := fetchMessages(t, tokenA, conv, 0, 50); len(before) != 3 {
		t.Fatalf("删除前 A 应见 3 条, got %d", len(before))
	}

	// A 本地删除第 1 条
	sendEnvelope(t, wsA, "delete_message", map[string]any{
		"conversation_id": conv, "server_msg_id": sid1,
	})
	time.Sleep(500 * time.Millisecond)

	if afterA := fetchMessages(t, tokenA, conv, 0, 50); len(afterA) != 2 {
		t.Fatalf("删除后 A 应见 2 条, got %d", len(afterA))
	}
	if afterB := fetchMessages(t, tokenB, conv, 0, 50); len(afterB) != 3 {
		t.Fatalf("删除不应影响 B, B 应见 3 条, got %d", len(afterB))
	}
}

// TestUpdateProfile 验证：PUT /users/me 改昵称/头像；GET /users/me 与 /users/:id 一致；部分更新不清空另一字段。
func TestUpdateProfile(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	token, id := register(t, "pf")

	nick := "新昵称-" + randStr()
	avatar := "http://localhost:8080/api/v1/media/" + randStr()
	if code := doJSON(t, http.MethodPut, "/api/v1/users/me", token,
		map[string]any{"nickname": nick, "avatar_url": avatar}, nil); code != http.StatusOK {
		t.Fatalf("PUT /users/me got %d", code)
	}

	var me struct {
		Nickname  string `json:"nickname"`
		AvatarURL string `json:"avatar_url"`
	}
	if code := doJSON(t, http.MethodGet, "/api/v1/users/me", token, nil, &me); code != http.StatusOK {
		t.Fatalf("GET /users/me got %d", code)
	}
	if me.Nickname != nick || me.AvatarURL != avatar {
		t.Fatalf("资料不符: %+v", me)
	}

	var other struct {
		Nickname string `json:"nickname"`
	}
	if code := doJSON(t, http.MethodGet, "/api/v1/users/"+id, token, nil, &other); code != http.StatusOK {
		t.Fatalf("GET /users/:id got %d", code)
	}
	if other.Nickname != nick {
		t.Fatalf("按 ID 查看昵称不符: got %q want %q", other.Nickname, nick)
	}

	// 部分更新：只改昵称，头像保持不变。
	nick2 := "仅昵称-" + randStr()
	if code := doJSON(t, http.MethodPut, "/api/v1/users/me", token,
		map[string]any{"nickname": nick2}, nil); code != http.StatusOK {
		t.Fatalf("部分更新 PUT got %d", code)
	}
	me = struct {
		Nickname  string `json:"nickname"`
		AvatarURL string `json:"avatar_url"`
	}{}
	if code := doJSON(t, http.MethodGet, "/api/v1/users/me", token, nil, &me); code != http.StatusOK {
		t.Fatalf("GET /users/me got %d", code)
	}
	if me.Nickname != nick2 {
		t.Fatalf("昵称未更新: got %q want %q", me.Nickname, nick2)
	}
	if me.AvatarURL != avatar {
		t.Fatalf("部分更新不应清空头像: got %q", me.AvatarURL)
	}
}

// TestGroupAnnouncement 验证：群主设置公告→详情返回；非群主被拒(403)。
func TestGroupAnnouncement(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	tokenA, _ := register(t, "anA")
	tokenB, idB := register(t, "anB")

	var grp struct {
		ConversationID string `json:"conversation_id"`
	}
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/group", tokenA,
		map[string]any{"name": "公告群", "member_ids": []string{idB}}, &grp); code != http.StatusOK {
		t.Fatalf("create group got %d", code)
	}

	text := "本群公告-" + randStr()
	path := "/api/v1/conversations/" + grp.ConversationID + "/announcement"
	if code := doJSON(t, http.MethodPost, path, tokenA,
		map[string]any{"announcement": text}, nil); code != http.StatusOK {
		t.Fatalf("set announcement got %d", code)
	}

	var detail struct {
		Conversation struct {
			Announcement string `json:"announcement"`
		} `json:"conversation"`
	}
	if code := doJSON(t, http.MethodGet, "/api/v1/conversations/"+grp.ConversationID, tokenA, nil, &detail); code != http.StatusOK {
		t.Fatalf("get detail got %d", code)
	}
	if detail.Conversation.Announcement != text {
		t.Fatalf("公告不符: got %q want %q", detail.Conversation.Announcement, text)
	}

	if code := doJSON(t, http.MethodPost, path, tokenB,
		map[string]any{"announcement": "篡改"}, nil); code != http.StatusForbidden {
		t.Fatalf("非群主设置公告应 403, got %d", code)
	}
}

// TestMessageReaction 验证：表情回应切换→广播 message_update 含 reactions，且落库持久。
func TestMessageReaction(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	tokenA, _ := register(t, "rtA")
	tokenB, idB := register(t, "rtB")
	conv := createDirect(t, tokenA, idB)
	wsA, wsB := wsDial(t, ctx, tokenA), wsDial(t, ctx, tokenB)
	defer wsA.CloseNow()
	defer wsB.CloseNow()
	time.Sleep(400 * time.Millisecond)

	sid := sendContentVia(t, wsA, conv, map[string]any{"type": 0, "text": "react-target-" + randStr()})
	sendEnvelope(t, wsA, "react_message", map[string]any{
		"conversation_id": conv, "server_msg_id": sid, "emoji": "👍", "on": true,
	})

	upd := awaitPayload(t, wsB, func(p map[string]any) bool {
		if p["server_msg_id"] != sid {
			return false
		}
		c, _ := p["content"].(map[string]any)
		r, _ := c["reactions"].(map[string]any)
		_, ok := r["👍"]
		return ok
	}, 5*time.Second)
	if upd == nil {
		t.Fatal("未收到含 reactions 的 message_update")
	}

	var res struct {
		Messages []struct {
			ID      string `json:"server_msg_id"`
			Content struct {
				Reactions map[string][]string `json:"reactions"`
			} `json:"content"`
		} `json:"messages"`
	}
	if code := doJSON(t, http.MethodGet, "/api/v1/conversations/"+conv+"/messages?limit=50", tokenA, nil, &res); code != http.StatusOK {
		t.Fatalf("history got %d", code)
	}
	var persisted bool
	for _, m := range res.Messages {
		if m.ID == sid {
			if users, has := m.Content.Reactions["👍"]; has && len(users) > 0 {
				persisted = true
			}
		}
	}
	if !persisted {
		t.Fatal("落库 reactions 缺失")
	}
}

// TestSystemMessage 验证：群主添加成员后生成 type=4 系统消息。
func TestSystemMessage(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	tokenA, _ := register(t, "sysA")
	_, idB := register(t, "sysB")
	_, idC := register(t, "sysC")

	var grp struct {
		ConversationID string `json:"conversation_id"`
	}
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/group", tokenA,
		map[string]any{"name": "系统群", "member_ids": []string{idB}}, &grp); code != http.StatusOK {
		t.Fatalf("create group got %d", code)
	}
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/"+grp.ConversationID+"/members/add", tokenA,
		map[string]any{"user_ids": []string{idC}}, nil); code != http.StatusOK {
		t.Fatalf("add member got %d", code)
	}

	var res struct {
		Messages []struct {
			Content struct {
				Type int16  `json:"type"`
				Text string `json:"text"`
			} `json:"content"`
		} `json:"messages"`
	}
	if code := doJSON(t, http.MethodGet, "/api/v1/conversations/"+grp.ConversationID+"/messages?limit=50", tokenA, nil, &res); code != http.StatusOK {
		t.Fatalf("history got %d", code)
	}
	var found bool
	for _, m := range res.Messages {
		if m.Content.Type == 4 && strings.Contains(m.Content.Text, "加入了群聊") {
			found = true
		}
	}
	if !found {
		t.Fatal("未发现成员加入的系统消息")
	}
}

// TestGlobalSearch 验证：/search/messages 命中自己的消息，且不越出成员会话范围。
func TestGlobalSearch(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	tokenA, _ := register(t, "gsA")
	_, idB := register(t, "gsB")
	tokenC, _ := register(t, "gsC")
	convAB := createDirect(t, tokenA, idB)
	convC := createDirect(t, tokenC, idB)

	needle := "gneedle-" + randStr()
	sendText(t, tokenA, convAB, "hello "+needle)
	// 同关键字发给 B-C 会话（A 不在其中），用于验证成员范围隔离。
	sendText(t, tokenC, convC, "hello "+needle+"-other")

	var res struct {
		Messages []struct {
			ConversationID string `json:"conversation_id"`
			Content        struct {
				Text string `json:"text"`
			} `json:"content"`
		} `json:"messages"`
	}
	if code := doJSON(t, http.MethodGet, "/api/v1/search/messages?q="+needle, tokenA, nil, &res); code != http.StatusOK {
		t.Fatalf("search got %d", code)
	}
	var hit bool
	for _, m := range res.Messages {
		if m.ConversationID == convC {
			t.Fatal("A 不应搜到 B-C 会话消息")
		}
		if strings.Contains(m.Content.Text, needle) {
			hit = true
		}
	}
	if !hit {
		t.Fatal("全局搜索未命中自己的消息")
	}
}

// memberRoles 返回会话内 user_id -> role 映射。
func memberRoles(t *testing.T, token, conv string) map[string]int {
	t.Helper()
	var d struct {
		Members []struct {
			UserID string `json:"user_id"`
			Role   int    `json:"role"`
		} `json:"members"`
	}
	if code := doJSON(t, http.MethodGet, "/api/v1/conversations/"+conv, token, nil, &d); code != http.StatusOK {
		t.Fatalf("detail got %d", code)
	}
	out := map[string]int{}
	for _, m := range d.Members {
		out[m.UserID] = m.Role
	}
	return out
}

// TestGroupRole 验证：转让群主 / 设取消管理员 / 管理员可加人但不可改名。
func TestGroupRole(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	tokenA, idA := register(t, "grA")
	tokenB, idB := register(t, "grB")
	tokenC, idC := register(t, "grC")
	_, idD := register(t, "grD")

	var g struct {
		ConversationID string `json:"conversation_id"`
	}
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/group", tokenA,
		map[string]any{"name": "角色群", "member_ids": []string{idB}}, &g); code != http.StatusOK {
		t.Fatalf("create group got %d", code)
	}
	conv := g.ConversationID

	// 1. A 转让给 B：B=2, A=0
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/"+conv+"/transfer", tokenA,
		map[string]any{"user_id": idB}, nil); code != http.StatusOK {
		t.Fatalf("transfer got %d", code)
	}
	if r := memberRoles(t, tokenA, conv); r[idB] != 2 || r[idA] != 0 {
		t.Fatalf("转让后角色错误 A=%d B=%d", r[idA], r[idB])
	}
	// 2. 原群主 A(现普通) 设管理员 -> 403
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/"+conv+"/members/role", tokenA,
		map[string]any{"user_id": idA, "role": 1}, nil); code != http.StatusForbidden {
		t.Fatalf("非群主设管理员期望 403，实际 %d", code)
	}
	// 3. 新群主 B 加 C 并设为管理员
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/"+conv+"/members/add", tokenB,
		map[string]any{"user_ids": []string{idC}}, nil); code != http.StatusOK {
		t.Fatalf("B add C got %d", code)
	}
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/"+conv+"/members/role", tokenB,
		map[string]any{"user_id": idC, "role": 1}, nil); code != http.StatusOK {
		t.Fatalf("setAdmin C got %d", code)
	}
	if r := memberRoles(t, tokenB, conv); r[idC] != 1 {
		t.Fatalf("C 应为管理员，实际 %d", r[idC])
	}
	// 4. 管理员 C 可加成员 D
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/"+conv+"/members/add", tokenC,
		map[string]any{"user_ids": []string{idD}}, nil); code != http.StatusOK {
		t.Fatalf("admin C add D got %d", code)
	}
	if _, n := detailNameCount(t, tokenB, conv); n != 4 {
		t.Fatalf("管理员加人后期望 4 成员，实际 %d", n)
	}
	// 5. 管理员 C 改名 -> 403（仅群主）
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/"+conv+"/rename", tokenC,
		map[string]any{"name": "x"}, nil); code != http.StatusForbidden {
		t.Fatalf("管理员改名期望 403，实际 %d", code)
	}
	// 6. 群主 B 不能改自己角色 -> 400
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/"+conv+"/members/role", tokenB,
		map[string]any{"user_id": idB, "role": 1}, nil); code != http.StatusBadRequest {
		t.Fatalf("改群主角色期望 400，实际 %d", code)
	}
	// 7. 转让回 A
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/"+conv+"/transfer", tokenB,
		map[string]any{"user_id": idA}, nil); code != http.StatusOK {
		t.Fatalf("transfer back got %d", code)
	}
	if r := memberRoles(t, tokenA, conv); r[idA] != 2 || r[idB] != 0 {
		t.Fatalf("回转让角色错误 A=%d B=%d", r[idA], r[idB])
	}
}

// TestPinnedMessage 验证：pin_message 切换置顶，广播 message_update，/pinned 列表同步。
func TestPinnedMessage(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	tokenA, _ := register(t, "pinA")
	tokenB, idB := register(t, "pinB")
	conv := createDirect(t, tokenA, idB)
	wsA, wsB := wsDial(t, ctx, tokenA), wsDial(t, ctx, tokenB)
	defer wsA.CloseNow()
	defer wsB.CloseNow()
	time.Sleep(400 * time.Millisecond)

	sid := sendContentVia(t, wsA, conv, map[string]any{"type": 0, "text": "pin-target-" + randStr()})
	sendEnvelope(t, wsA, "pin_message", map[string]any{
		"conversation_id": conv, "server_msg_id": sid, "on": true,
	})
	upd := awaitPayload(t, wsB, func(p map[string]any) bool {
		if p["server_msg_id"] != sid {
			return false
		}
		c, _ := p["content"].(map[string]any)
		return c["pinned"] == true
	}, 5*time.Second)
	if upd == nil {
		t.Fatal("未收到含 pinned 的 message_update")
	}

	var res struct {
		Messages []struct {
			ID string `json:"server_msg_id"`
		} `json:"messages"`
	}
	if code := doJSON(t, http.MethodGet, "/api/v1/conversations/"+conv+"/pinned", tokenA, nil, &res); code != http.StatusOK {
		t.Fatalf("pinned got %d", code)
	}
	var found bool
	for _, m := range res.Messages {
		if m.ID == sid {
			found = true
		}
	}
	if !found {
		t.Fatal("/pinned 未返回置顶消息")
	}

	// 取消置顶。
	sendEnvelope(t, wsA, "pin_message", map[string]any{
		"conversation_id": conv, "server_msg_id": sid, "on": false,
	})
	awaitPayload(t, wsB, func(p map[string]any) bool {
		if p["server_msg_id"] != sid {
			return false
		}
		c, _ := p["content"].(map[string]any)
		return c["pinned"] == false || c["pinned"] == nil
	}, 5*time.Second)
	res.Messages = nil
	if code := doJSON(t, http.MethodGet, "/api/v1/conversations/"+conv+"/pinned", tokenA, nil, &res); code != http.StatusOK {
		t.Fatalf("pinned2 got %d", code)
	}
	for _, m := range res.Messages {
		if m.ID == sid {
			t.Fatal("取消置顶后仍在 /pinned")
		}
	}
}

// TestMentionAll 验证：群内 mention_all 消息令他人会话出现提及徒标，发送者自己则无。
func TestMentionAll(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	tokenA, _ := register(t, "maA")
	tokenB, idB := register(t, "maB")
	var grp struct {
		ConversationID string `json:"conversation_id"`
	}
	if code := doJSON(t, http.MethodPost, "/api/v1/conversations/group", tokenA,
		map[string]any{"name": "@群", "member_ids": []string{idB}}, &grp); code != http.StatusOK {
		t.Fatalf("create group got %d", code)
	}
	conv := grp.ConversationID
	wsA, wsB := wsDial(t, ctx, tokenA), wsDial(t, ctx, tokenB)
	defer wsA.CloseNow()
	defer wsB.CloseNow()
	time.Sleep(400 * time.Millisecond)

	sendContentVia(t, wsA, conv, map[string]any{"type": 0, "text": "大家好 @所有人", "mention_all": true})
	got := awaitPayload(t, wsB, func(p map[string]any) bool {
		c, _ := p["content"].(map[string]any)
		return c["mention_all"] == true
	}, 5*time.Second)
	if got == nil {
		t.Fatal("B 未收到 mention_all 消息")
	}

	var resp struct {
		Conversations []struct {
			ID        string `json:"id"`
			MentionMe bool   `json:"mention_me"`
		} `json:"conversations"`
	}
	if code := doJSON(t, http.MethodGet, "/api/v1/conversations", tokenB, nil, &resp); code != http.StatusOK {
		t.Fatalf("list convs B got %d", code)
	}
	var bFlag bool
	for _, c := range resp.Conversations {
		if c.ID == conv {
			bFlag = c.MentionMe
		}
	}
	if !bFlag {
		t.Fatal("B 会话应有提及徒标")
	}
	if code := doJSON(t, http.MethodGet, "/api/v1/conversations", tokenA, nil, &resp); code != http.StatusOK {
		t.Fatalf("list convs A got %d", code)
	}
	for _, c := range resp.Conversations {
		if c.ID == conv && c.MentionMe {
			t.Fatal("发送者 A 不应出现提及徒标")
		}
	}
}

// TestReadSyncMultiDevice 验证：同一用户一个设备 mark_read 后，其另一设备收到 read_sync。
func TestReadSyncMultiDevice(t *testing.T) {
	if _, err := http.Get(baseURL() + "/healthz"); err != nil {
		t.Skipf("后端不可达(%s): %v", baseURL(), err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	tokenA, _ := register(t, "rdA")
	_, idB := register(t, "rdB")
	conv := createDirect(t, tokenA, idB)

	dial := func(dev string) *websocket.Conn {
		c, _, err := websocket.Dial(ctx, wsURL()+"?token="+tokenA+"&device_id="+dev, nil)
		if err != nil {
			t.Fatal(err)
		}
		return c
	}
	conn1, conn2 := dial("d1"), dial("d2")
	defer conn1.CloseNow()
	defer conn2.CloseNow()
	time.Sleep(400 * time.Millisecond)

	sendEnvelope(t, conn1, "mark_read", map[string]any{"conversation_id": conv, "max_seq": 5})
	got := awaitPayload(t, conn2, func(p map[string]any) bool {
		return p["conversation_id"] == conv && p["max_seq"] != nil && p["user_id"] == nil
	}, 5*time.Second)
	if got == nil {
		t.Fatal("同用户另一设备未收到 read_sync")
	}
	if ms, _ := got["max_seq"].(float64); ms != 5 {
		t.Fatalf("read_sync max_seq 期望 5，实际 %v", got["max_seq"])
	}
}
