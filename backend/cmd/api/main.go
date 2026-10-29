package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/birrmetrics/birrmetrics-api/internal/config"
	"github.com/birrmetrics/birrmetrics-api/internal/database"
	"github.com/birrmetrics/birrmetrics-api/internal/server"
	"github.com/birrmetrics/birrmetrics-api/internal/users/repo"
	"github.com/birrmetrics/birrmetrics-api/internal/users/service"
)

func main() {
	log.Println("Starting BirrMetrics API...")

	cfg := config.LoadConfig()

	pool := database.ConnectDB(cfg.DBUrl)
	defer pool.Close()

	userRepo := repo.NewUserRepo(pool)
	userSvc := service.NewUserService(userRepo)

	router := server.New(cfg, userSvc)

	addr := fmt.Sprintf(":%s", cfg.Port)
	log.Printf("🚀 Server running on http://localhost%s", addr)

	if err := http.ListenAndServe(addr, router); err != nil {
		log.Fatalf("Server error: %v", err)
	}
}
