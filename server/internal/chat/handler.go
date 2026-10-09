package chat

import (
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"

	"github.com/tss/depth/server/internal/message"
	"github.com/tss/depth/server/pkg/middleware"
)

// Handler 提供会话相关的 HTTP 接口。
type Handler struct {
	repo   *Repository
	msgSvc *message.Service
}

// NewHandler 构造会话处理器。
func NewHandler(repo *Repository, msgSvc *message.Service) *Handler {
	return &Handler{repo: repo, msgSvc: msgSvc}
}

type createDirectReq struct {
	PeerID string `json:"peer_id" binding:"required,uuid"`
}

type createGroupReq struct {
	Name      string   `json:"name" binding:"required,max=128"`
	MemberIDs []string `json:"member_ids" binding:"required,min=1,dive,uuid"`
}

// CreateDirect 处理 POST /api/v1/conversations/direct
func (h *Handler) CreateDirect(c *gin.Context) {
	var req createDirectReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	uid := middleware.CtxUserID(c)
	convID, err := h.repo.CreateDirect(c.Request.Context(), uid, req.PeerID)
	if err != nil {
		slog.Error("create direct failed", "user", uid, "peer", req.PeerID, "err", err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "创建会话失败"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"conversation_id": convID})
}

// CreateGroup 处理 POST /api/v1/conversations/group
func (h *Handler) CreateGroup(c *gin.Context) {
	var req createGroupReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	uid := middleware.CtxUserID(c)
	convID, err := h.repo.CreateGroup(c.Request.Context(), uid, req.Name, req.MemberIDs)
	if err != nil {
		slog.Error("create group failed", "user", uid, "name", req.Name, "err", err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "创建群聊失败"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"conversation_id": convID})
}

// List 处理 GET /api/v1/conversations
func (h *Handler) List(c *gin.Context) {
	uid := middleware.CtxUserID(c)
	convs, err := h.repo.ListForUser(c.Request.Context(), uid)
	if err != nil {
		slog.Error("list conversations failed", "user", uid, "err", err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取会话列表失败"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"conversations": convs})
}

// Messages 处理 GET /api/v1/conversations/:id/messages?before_seq=&limit=
func (h *Handler) Messages(c *gin.Context) {
	convID := c.Param("id")
	var beforeSeq int64
	if v := c.Query("before_seq"); v != "" {
		beforeSeq, _ = strconv.ParseInt(v, 10, 64)
	}
	limit := 30
	if v, err := strconv.Atoi(c.Query("limit")); err == nil && v > 0 {
		limit = v
	}
	uid := middleware.CtxUserID(c)
	msgs, err := h.msgSvc.History(c.Request.Context(), uid, convID, beforeSeq, limit)
	if err != nil {
		slog.Error("list history failed", "conv", convID, "err", err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取历史消息失败"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"messages": msgs})
}

// Search 处理 GET /api/v1/conversations/:id/messages/search?q=&limit=
// —— 会话内按文本关键字检索（仅未撤回的文本消息）。
func (h *Handler) Search(c *gin.Context) {
	convID := c.Param("id")
	q := c.Query("q")
	limit := 50
	if v, err := strconv.Atoi(c.Query("limit")); err == nil && v > 0 {
		limit = v
	}
	msgs, err := h.msgSvc.Search(c.Request.Context(), convID, q, limit)
	if err != nil {
		slog.Error("search messages failed", "conv", convID, "q", q, "err", err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "搜索消息失败"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"messages": msgs})
}

// SearchMessages 处理 GET /api/v1/search/messages?q=&limit= —— 跨会话的全局消息检索。
func (h *Handler) SearchMessages(c *gin.Context) {
	q := c.Query("q")
	limit := 50
	if v, err := strconv.Atoi(c.Query("limit")); err == nil && v > 0 {
		limit = v
	}
	uid := middleware.CtxUserID(c)
	msgs, err := h.msgSvc.SearchGlobal(c.Request.Context(), uid, q, limit)
	if err != nil {
		slog.Error("global search failed", "user", uid, "q", q, "err", err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "搜索失败"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"messages": msgs})
}

// Get 处理 GET /api/v1/conversations/:id —— 返回会话详情与成员。
func (h *Handler) Get(c *gin.Context) {
	convID := c.Param("id")
	conv, members, err := h.repo.Detail(c.Request.Context(), convID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "会话不存在"})
			return
		}
		slog.Error("get conversation detail failed", "conv", convID, "err", err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取会话详情失败"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"conversation": conv, "members": members})
}

// RegisterRoutes 挂载到受保护的路由组。
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.POST("/conversations/direct", h.CreateDirect)
	rg.POST("/conversations/group", h.CreateGroup)
	rg.GET("/conversations", h.List)
	rg.GET("/conversations/:id", h.Get)
	rg.GET("/conversations/:id/messages", h.Messages)
	rg.GET("/conversations/:id/messages/search", h.Search)
	rg.GET("/search/messages", h.SearchMessages)

	rg.POST("/conversations/:id/rename", h.Rename)
	rg.POST("/conversations/:id/announcement", h.SetAnnouncement)
	rg.POST("/conversations/:id/transfer", h.TransferOwner)
	rg.POST("/conversations/:id/members/role", h.SetAdmin)
	rg.POST("/conversations/:id/members/add", h.AddMembers)
	rg.POST("/conversations/:id/members/remove", h.RemoveMember)
	rg.POST("/conversations/:id/leave", h.Leave)
	rg.POST("/conversations/:id/pin", h.Pin)
	rg.POST("/conversations/:id/mute", h.Mute)
	rg.DELETE("/conversations/:id", h.Hide)
}

// respondConvErr 统一处理群管理错误：ErrForbidden 403，其余记日得 500。
func respondConvErr(c *gin.Context, err error, fallback string) {
	if errors.Is(err, ErrForbidden) {
		c.JSON(http.StatusForbidden, gin.H{"error": "需要群主/管理员权限"})
		return
	}
	if errors.Is(err, ErrNotMember) || errors.Is(err, ErrOwnerImmutable) {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	slog.Error(fallback, "conv", c.Param("id"), "err", err.Error())
	c.JSON(http.StatusInternalServerError, gin.H{"error": fallback})
}

type renameReq struct {
	Name string `json:"name" binding:"required,max=128"`
}

type announcementReq struct {
	Announcement string `json:"announcement" binding:"max=512"`
}

type addMembersReq struct {
	UserIDs []string `json:"user_ids" binding:"required,min=1,dive,uuid"`
}

type removeMemberReq struct {
	UserID string `json:"user_id" binding:"required,uuid"`
}

type pinReq struct {
	Pinned bool `json:"pinned"`
}

type muteReq struct {
	Muted bool `json:"muted"`
}

type transferReq struct {
	UserID string `json:"user_id" binding:"required,uuid"`
}

type setRoleReq struct {
	UserID string `json:"user_id" binding:"required,uuid"`
	Role   int16  `json:"role" binding:"oneof=0 1"`
}

// Rename 处理 POST /conversations/:id/rename。
func (h *Handler) Rename(c *gin.Context) {
	var req renameReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.repo.Rename(c.Request.Context(), c.Param("id"), middleware.CtxUserID(c), req.Name); err != nil {
		respondConvErr(c, err, "改名失败")
		return
	}
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

// SetAnnouncement 处理 POST /conversations/:id/announcement。
func (h *Handler) SetAnnouncement(c *gin.Context) {
	var req announcementReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.repo.SetAnnouncement(c.Request.Context(), c.Param("id"), middleware.CtxUserID(c), req.Announcement); err != nil {
		respondConvErr(c, err, "设置公告失败")
		return
	}
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

// TransferOwner 处理 POST /conversations/:id/transfer —— 转让群主（仅群主）。
func (h *Handler) TransferOwner(c *gin.Context) {
	var req transferReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	ctx := c.Request.Context()
	convID := c.Param("id")
	actor := middleware.CtxUserID(c)
	if err := h.repo.TransferOwner(ctx, convID, actor, req.UserID); err != nil {
		respondConvErr(c, err, "转让群主失败")
		return
	}
	if h.msgSvc != nil {
		if name, err := h.repo.DisplayName(ctx, req.UserID); err == nil {
			if err := h.msgSvc.AppendSystem(ctx, convID, actor, fmt.Sprintf("「%s」成为群主", name)); err != nil {
				slog.Warn("append transfer system message failed", "conv", convID, "err", err.Error())
			}
		}
	}
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

// SetAdmin 处理 POST /conversations/:id/members/role —— 设/取消管理员（仅群主，role 0/1）。
func (h *Handler) SetAdmin(c *gin.Context) {
	var req setRoleReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	ctx := c.Request.Context()
	convID := c.Param("id")
	actor := middleware.CtxUserID(c)
	if err := h.repo.SetMemberRole(ctx, convID, actor, req.UserID, req.Role); err != nil {
		respondConvErr(c, err, "设置管理员失败")
		return
	}
	if h.msgSvc != nil {
		if name, err := h.repo.DisplayName(ctx, req.UserID); err == nil {
			act := "被设为管理员"
			if req.Role == 0 {
				act = "被取消管理员"
			}
			if err := h.msgSvc.AppendSystem(ctx, convID, actor, fmt.Sprintf("「%s」%s", name, act)); err != nil {
				slog.Warn("append role system message failed", "conv", convID, "err", err.Error())
			}
		}
	}
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

// AddMembers 处理 POST /conversations/:id/members/add。
func (h *Handler) AddMembers(c *gin.Context) {
	var req addMembersReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	ctx := c.Request.Context()
	convID := c.Param("id")
	actor := middleware.CtxUserID(c)
	if err := h.repo.AddMembers(ctx, convID, actor, req.UserIDs); err != nil {
		respondConvErr(c, err, "添加成员失败")
		return
	}
	if h.msgSvc != nil {
		for _, uid := range req.UserIDs {
			if name, err := h.repo.DisplayName(ctx, uid); err == nil {
				if err := h.msgSvc.AppendSystem(ctx, convID, actor, fmt.Sprintf("「%s」加入了群聊", name)); err != nil {
					slog.Warn("append join system message failed", "conv", convID, "err", err.Error())
				}
			}
		}
	}
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

// RemoveMember 处理 POST /conversations/:id/members/remove。
func (h *Handler) RemoveMember(c *gin.Context) {
	var req removeMemberReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	ctx := c.Request.Context()
	convID := c.Param("id")
	actor := middleware.CtxUserID(c)
	if err := h.repo.RemoveMember(ctx, convID, actor, req.UserID); err != nil {
		respondConvErr(c, err, "移除成员失败")
		return
	}
	if h.msgSvc != nil {
		if name, err := h.repo.DisplayName(ctx, req.UserID); err == nil {
			if err := h.msgSvc.AppendSystem(ctx, convID, actor, fmt.Sprintf("「%s」被移出群聊", name)); err != nil {
				slog.Warn("append remove system message failed", "conv", convID, "err", err.Error())
			}
		}
	}
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

// Leave 处理 POST /conversations/:id/leave。
func (h *Handler) Leave(c *gin.Context) {
	ctx := c.Request.Context()
	convID := c.Param("id")
	uid := middleware.CtxUserID(c)
	if err := h.repo.Leave(ctx, convID, uid); err != nil {
		respondConvErr(c, err, "退出会话失败")
		return
	}
	if h.msgSvc != nil {
		if name, err := h.repo.DisplayName(ctx, uid); err == nil {
			if err := h.msgSvc.AppendSystem(ctx, convID, uid, fmt.Sprintf("「%s」退出了群聊", name)); err != nil {
				slog.Warn("append leave system message failed", "conv", convID, "err", err.Error())
			}
		}
	}
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

// Pin 处理 POST /conversations/:id/pin。
func (h *Handler) Pin(c *gin.Context) {
	var req pinReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.repo.SetPin(c.Request.Context(), c.Param("id"), middleware.CtxUserID(c), req.Pinned); err != nil {
		respondConvErr(c, err, "置顶设置失败")
		return
	}
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

// Mute 处理 POST /conversations/:id/mute。
func (h *Handler) Mute(c *gin.Context) {
	var req muteReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.repo.SetMute(c.Request.Context(), c.Param("id"), middleware.CtxUserID(c), req.Muted); err != nil {
		respondConvErr(c, err, "免打扰设置失败")
		return
	}
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

// Hide 处理 DELETE /conversations/:id（从我的列表软删除）。
func (h *Handler) Hide(c *gin.Context) {
	if err := h.repo.Hide(c.Request.Context(), c.Param("id"), middleware.CtxUserID(c)); err != nil {
		respondConvErr(c, err, "删除会话失败")
		return
	}
	c.JSON(http.StatusOK, gin.H{"ok": true})
}
