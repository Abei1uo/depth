// Package middleware 提供跨模块复用的 Gin 中间件。
package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// ctxKeyUserID 是注入到 gin.Context 的用户 ID 键。
const ctxKeyUserID = "uid"

// CtxUserID 从上下文读取已认证用户 ID。
func CtxUserID(c *gin.Context) string {
	return c.GetString(ctxKeyUserID)
}

// TokenVerifier 抽象令牌校验能力：输入访问令牌，返回其归属用户 ID。
// 该接口不引用具体 auth 包，避免 middleware 与 auth 形成导入环。
type TokenVerifier interface {
	UserIDFromToken(tokenStr string) (string, error)
}

// Auth 校验 Authorization: Bearer <token>，失败返回 401。
func Auth(v TokenVerifier) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if header == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "缺少认证头"})
			return
		}
		parts := strings.SplitN(header, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "认证头格式错误"})
			return
		}
		userID, err := v.UserIDFromToken(strings.TrimSpace(parts[1]))
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "令牌无效或已过期"})
			return
		}
		c.Set(ctxKeyUserID, userID)
		c.Next()
	}
}
