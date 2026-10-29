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

	// 1. Load Config
	cfg := config.LoadConfig()

	// 2. Connect to Database
	pool := database.ConnectDB(cfg.DBUrl)
	defer pool.Close()

	// 3. Initialize Repositories & Services
	userRepo := repo.NewUserRepo(pool)
	userSvc := service.NewUserService(userRepo)

	// 4. Setup Router
	router := server.New(cfg, userSvc, pool)

	// 5. Start Server
	addr := fmt.Sprintf(":%s", cfg.Port)
	log.Printf("🚀 Server running on http://localhost%s", addr)

	if err := http.ListenAndServe(addr, router); err != nil {
		log.Fatalf("Server error: %v", err)
	}
}
