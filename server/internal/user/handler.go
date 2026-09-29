package user

import (
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
		c.JSON(http.StatusInternalServerError, gin.H{"error": "搜索失败"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"users": users})
}

// RegisterRoutes 挂载到受保护的路由组。
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.GET("/users/me", h.Me)
	rg.GET("/users/search", h.Search)
}
