package auth

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Handler 挂载认证相关的 HTTP 路由。
type Handler struct {
	svc *Service
}

// NewHandler 构造认证处理器。
func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

type registerReq struct {
	Username string `json:"username" binding:"required,min=3,max=64"`
	Nickname string `json:"nickname" binding:"max=64"`
	Password string `json:"password" binding:"required,min=6,max=128"`
}

type loginReq struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type refreshReq struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// Register 处理 POST /api/v1/auth/register
func (h *Handler) Register(c *gin.Context) {
	var req registerReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	pair, err := h.svc.Register(c.Request.Context(), req.Username, req.Nickname, req.Password)
	if err != nil {
		respondAuthError(c, err)
		return
	}
	c.JSON(http.StatusCreated, pair)
}

// Login 处理 POST /api/v1/auth/login
func (h *Handler) Login(c *gin.Context) {
	var req loginReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	pair, err := h.svc.Login(c.Request.Context(), req.Username, req.Password)
	if err != nil {
		respondAuthError(c, err)
		return
	}
	c.JSON(http.StatusOK, pair)
}

// Refresh 处理 POST /api/v1/auth/refresh
func (h *Handler) Refresh(c *gin.Context) {
	var req refreshReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	pair, err := h.svc.Refresh(c.Request.Context(), req.RefreshToken)
	if err != nil {
		respondAuthError(c, err)
		return
	}
	c.JSON(http.StatusOK, pair)
}

func respondAuthError(c *gin.Context, err error) {
	switch err {
	case ErrUsernameTaken:
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
	case ErrInvalidCred, ErrInvalidToken:
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
	default:
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
	}
}

// Register 将路由注册到给定的路由组。
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.POST("/register", h.Register)
	rg.POST("/login", h.Login)
	rg.POST("/refresh", h.Refresh)
}
