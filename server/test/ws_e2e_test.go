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
	"net/http"
	"os"
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
