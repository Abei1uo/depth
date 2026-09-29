//go:build integration

// Package e2e 针对真实运行的后端（HTTP + WebSocket + PG + Redis）做端到端验证。
// 运行前提：后端已在 BASE（默认 http://localhost:8080）启动，PG/Redis 就绪。
//   go test -tags=integration ./test/... -run TestWS -v
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
