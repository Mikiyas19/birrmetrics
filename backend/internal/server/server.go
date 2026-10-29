package server

import (
	"net/http"

	"github.com/birrmetrics/birrmetrics-api/internal/auth"
	"github.com/birrmetrics/birrmetrics-api/internal/config"
	sync_handler "github.com/birrmetrics/birrmetrics-api/internal/sync/handler"
	sync_service "github.com/birrmetrics/birrmetrics-api/internal/sync/service"
	"github.com/birrmetrics/birrmetrics-api/internal/users/service"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/jackc/pgx/v5/pgxpool"
)

func New(cfg *config.Config, userSvc *service.UserService, db *pgxpool.Pool) *chi.Mux {
	r := chi.NewRouter()

	// Standard middleware
	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	// CORS
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type"},
		AllowCredentials: false,
		MaxAge:           300,
	}))

	// Health check
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"ok"}`))
	})

	// Initialize handlers
	authHandler := auth.NewHandler(cfg, userSvc)

	syncSvc := sync_service.NewSyncService(db)
	syncHandler := sync_handler.NewSyncHandler(syncSvc)

	r.Route("/api/v1", func(r chi.Router) {
		// Public auth routes
		r.Route("/auth", func(r chi.Router) {
			r.Post("/register", authHandler.Register)
			r.Post("/login", authHandler.Login)
		})

		// Protected routes (require JWT)
		r.Group(func(r chi.Router) {
			r.Use(auth.Middleware(cfg.JWTAccessSecret))

			// Auth verification
			r.Get("/auth/me", authHandler.Me)

			// Sync endpoints
			r.Post("/sync/batch", syncHandler.Push)
			r.Get("/sync/pull", syncHandler.Pull)
		})
	})

	return r
}
