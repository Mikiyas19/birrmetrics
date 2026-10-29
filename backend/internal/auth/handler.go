package auth

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/birrmetrics/birrmetrics-api/internal/config"
	"github.com/birrmetrics/birrmetrics-api/internal/shared/response"
	"github.com/birrmetrics/birrmetrics-api/internal/users/service"
)

type Handler struct {
	cfg     *config.Config
	userSvc *service.UserService
}

func NewHandler(cfg *config.Config, userSvc *service.UserService) *Handler {
	return &Handler{cfg: cfg, userSvc: userSvc}
}

type registerReq struct {
	Email    string `json:"email"`
	Password string `json:"password"`
	FullName string `json:"full_name"`
}

type loginReq struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type authResp struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	User         struct {
		ID    int    `json:"id"`
		Email string `json:"email"`
		Name  string `json:"name"`
	} `json:"user"`
}

func (h *Handler) Register(w http.ResponseWriter, r *http.Request) {
	var req registerReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.Error(w, http.StatusBadRequest, "invalid request body")
		return
	}

	u, err := h.userSvc.Register(r.Context(), req.Email, req.Password, req.FullName)
	if err != nil {
		response.Error(w, http.StatusBadRequest, err.Error())
		return
	}

	h.respondWithTokens(w, u.ID, u.Email, u.FullName)
}

func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var req loginReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.Error(w, http.StatusBadRequest, "invalid request body")
		return
	}

	u, err := h.userSvc.Login(r.Context(), req.Email, req.Password)
	if err != nil {
		response.Error(w, http.StatusUnauthorized, err.Error())
		return
	}

	h.respondWithTokens(w, u.ID, u.Email, u.FullName)
}

func (h *Handler) Me(w http.ResponseWriter, r *http.Request) {
	uid, ok := UserIDFromContext(r.Context())
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthenticated")
		return
	}
	u, err := h.userSvc.GetByID(r.Context(), uid)
	if err != nil || u == nil {
		response.Error(w, http.StatusNotFound, "user not found")
		return
	}
	response.JSON(w, http.StatusOK, map[string]any{
		"id":    u.ID,
		"email": u.Email,
		"name":  u.FullName,
	})
}

func (h *Handler) respondWithTokens(w http.ResponseWriter, uid int, email, fullName string) {
	accessTTL, _ := time.ParseDuration(h.cfg.JWTAccessTTL)
	refreshTTL, _ := time.ParseDuration(h.cfg.JWTRefreshTTL)

	accessToken, err := GenerateToken(uid, email, h.cfg.JWTAccessSecret, accessTTL)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "failed to create access token")
		return
	}

	refreshToken, err := GenerateToken(uid, email, h.cfg.JWTRefreshSecret, refreshTTL)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "failed to create refresh token")
		return
	}

	resp := authResp{AccessToken: accessToken, RefreshToken: refreshToken}
	resp.User.ID = uid
	resp.User.Email = email
	resp.User.Name = fullName
	response.JSON(w, http.StatusOK, resp)
}
