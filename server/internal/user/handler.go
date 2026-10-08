package user

import (
	"errors"
	"log/slog"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/tss/depth/server/pkg/middleware"
)

// Handler 提供用户相关的 HTTP 接口。
type Handler struct {
	repo *Repository
}

// NewHandler 构造用户处理器。
func NewHandler(repo *Repository) *Handler { return &Handler{repo: repo} }

// Me 处理 GET /api/v1/users/me —— 返回当前登录用户。
func (h *Handler) Me(c *gin.Context) {
	uid := middleware.CtxUserID(c)
	u, err := h.repo.ByID(c.Request.Context(), uid)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "用户不存在"})
		return
	}
	c.JSON(http.StatusOK, u)
}

type updateProfileReq struct {
	Nickname  *string `json:"nickname" binding:"omitempty,max=64"`
	AvatarURL *string `json:"avatar_url" binding:"omitempty,max=512"`
}

// UpdateMe 处理 PUT /api/v1/users/me —— 修改本人昵称/头像。
func (h *Handler) UpdateMe(c *gin.Context) {
	var req updateProfileReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	uid := middleware.CtxUserID(c)
	if err := h.repo.UpdateProfile(c.Request.Context(), uid, req.Nickname, req.AvatarURL); err != nil {
		slog.Error("update profile failed", "user", uid, "err", err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "保存资料失败"})
		return
	}
	u, err := h.repo.ByID(c.Request.Context(), uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "保存资料失败"})
		return
	}
	c.JSON(http.StatusOK, u)
}

// GetByID 处理 GET /api/v1/users/:id —— 查看他人资料。
func (h *Handler) GetByID(c *gin.Context) {
	u, err := h.repo.ByID(c.Request.Context(), c.Param("id"))
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "用户不存在"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取资料失败"})
		return
	}
	c.JSON(http.StatusOK, u)
}

// Search 处理 GET /api/v1/users/search?q=xxx&limit=20
func (h *Handler) Search(c *gin.Context) {
	q := c.Query("q")
	if q == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "缺少查询参数 q"})
		return
	}
	limit := 20
	if v, err := strconv.Atoi(c.Query("limit")); err == nil && v > 0 && v <= 50 {
		limit = v
	}
	users, err := h.repo.Search(c.Request.Context(), q, limit)
	if err != nil {
		slog.Error("user search failed", "q", q, "err", err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "搜索失败"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"users": users})
}

// RegisterRoutes 挂载到受保护的路由组。
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.GET("/users/me", h.Me)
	rg.PUT("/users/me", h.UpdateMe)
	rg.GET("/users/search", h.Search)
	rg.GET("/users/:id", h.GetByID)
}
