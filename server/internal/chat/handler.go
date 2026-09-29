package chat

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/tss/depth/server/internal/message"
	"github.com/tss/depth/server/pkg/middleware"
)

// Handler 提供会话相关的 HTTP 接口。
type Handler struct {
	repo    *Repository
	msgSvc  *message.Service
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
	msgs, err := h.msgSvc.History(c.Request.Context(), convID, beforeSeq, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取历史消息失败"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"messages": msgs})
}

// RegisterRoutes 挂载到受保护的路由组。
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.POST("/conversations/direct", h.CreateDirect)
	rg.POST("/conversations/group", h.CreateGroup)
	rg.GET("/conversations", h.List)
	rg.GET("/conversations/:id/messages", h.Messages)
}
