package handler

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/birrmetrics/birrmetrics-api/internal/auth"
	"github.com/birrmetrics/birrmetrics-api/internal/shared/response"
	"github.com/birrmetrics/birrmetrics-api/internal/sync/service"
)

type SyncHandler struct {
	svc *service.SyncService
}

func NewSyncHandler(svc *service.SyncService) *SyncHandler {
	return &SyncHandler{svc: svc}
}

// POST /api/v1/sync/batch
func (h *SyncHandler) Push(w http.ResponseWriter, r *http.Request) {
	uid, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthenticated")
		return
	}

	var payload service.SyncBatch
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		response.Error(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if err := h.svc.ProcessBatch(r.Context(), uid, payload); err != nil {
		response.Error(w, http.StatusInternalServerError, err.Error())
		return
	}

	response.JSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// GET /api/v1/sync/pull?since=timestamp
func (h *SyncHandler) Pull(w http.ResponseWriter, r *http.Request) {
	uid, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthenticated")
		return
	}

	sinceStr := r.URL.Query().Get("since")
	var since time.Time
	if sinceStr == "" {
		since = time.Time{} // pull everything
	} else {
		var err error
		since, err = time.Parse(time.RFC3339, sinceStr)
		if err != nil {
			response.Error(w, http.StatusBadRequest, "invalid since timestamp")
			return
		}
	}

	result, err := h.svc.GetChangesSince(r.Context(), uid, since)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, err.Error())
		return
	}

	response.JSON(w, http.StatusOK, result)
}
