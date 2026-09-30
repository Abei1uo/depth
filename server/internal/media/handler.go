package media

import (
	"io"
	"log/slog"
	"mime"
	"net/http"
	"path/filepath"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/tss/depth/server/pkg/middleware"
)

const maxUploadBytes = 16 << 20 // 16MB

// Handler 提供媒体上传/下载 HTTP 接口，仅依赖 Store 接口。
type Handler struct {
	store Store
	repo  *Repo
	log   *slog.Logger
}

// NewHandler 构造媒体处理器。
func NewHandler(store Store, repo *Repo, log *slog.Logger) *Handler {
	return &Handler{store: store, repo: repo, log: log}
}

// RegisterAuthed 挂到受保护组：上传需登录。
func (h *Handler) RegisterAuthed(rg *gin.RouterGroup) {
	rg.POST("/media", h.Upload)
}

// RegisterPublic 挂到公开组：下载凭不可猜的 id 直取，供 <img> 无 Authorization 头使用。
func (h *Handler) RegisterPublic(rg *gin.RouterGroup) {
	rg.GET("/media/:id", h.Download)
}

// Upload 处理 POST /media（multipart 字段 file）。
func (h *Handler) Upload(c *gin.Context) {
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxUploadBytes)
	if err := c.Request.ParseMultipartForm(maxUploadBytes); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "解析上传失败"})
		return
	}
	defer c.Request.MultipartForm.RemoveAll()

	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "缺少文件字段 file"})
		return
	}
	defer file.Close()

	if header.Size > maxUploadBytes {
		c.JSON(http.StatusRequestEntityTooLarge, gin.H{"error": "文件过大(>16MB)"})
		return
	}

	ct := header.Header.Get("Content-Type")
	if ct == "" {
		ct = mime.TypeByExtension(filepath.Ext(header.Filename))
	}
	key := uuid.NewString() + filepath.Ext(header.Filename)

	if err := h.store.Put(c.Request.Context(), key, file, header.Size, ct); err != nil {
		h.log.Error("media put failed", "user", middleware.CtxUserID(c), "err", err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "存储失败"})
		return
	}

	rec := &Record{UploaderID: middleware.CtxUserID(c), ObjKey: key, Mime: ct, Size: header.Size}
	if err := h.repo.Create(c.Request.Context(), rec); err != nil {
		h.log.Error("media record create failed", "user", rec.UploaderID, "err", err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "登记失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"media_id": rec.ID,
		"url":      publicURL(c, rec.ID),
		"mime":     rec.Mime,
		"size":     rec.Size,
	})
}

// Download 处理 GET /media/:id —— 从对象存储流式转发。
func (h *Handler) Download(c *gin.Context) {
	rec, err := h.repo.Get(c.Request.Context(), c.Param("id"))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "媒体不存在"})
		return
	}
	body, ct, err := h.store.Get(c.Request.Context(), rec.ObjKey)
	if err != nil {
		h.log.Error("media get failed", "id", rec.ID, "err", err.Error())
		c.JSON(http.StatusNotFound, gin.H{"error": "读取失败"})
		return
	}
	defer body.Close()

	c.Header("Content-Type", ct)
	c.Header("Cache-Control", "private, max-age=3600")
	_, _ = io.Copy(c.Writer, body)
}

// publicURL 依据请求 Host 构造下载绝对 URL（同一访问设备必可达）。
func publicURL(c *gin.Context, id string) string {
	scheme := "http"
	if c.Request.TLS != nil || c.GetHeader("X-Forwarded-Proto") == "https" {
		scheme = "https"
	}
	return scheme + "://" + c.Request.Host + "/api/v1/media/" + id
}
