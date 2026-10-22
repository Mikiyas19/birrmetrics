package main

import (
	"fmt"
	"log"

	"github.com/birrmetrics/birrmetrics-api/internal/config"
	"github.com/birrmetrics/birrmetrics-api/internal/database"
)

func main() {
	log.Println("Starting BirrMetrics API...")

	// 1. Load Config
	cfg := config.LoadConfig()

	// 2. Connect to Database
	dbPool := database.ConnectDB(cfg.DBUrl)
	defer dbPool.Close()

	// 3. Start HTTP Server (Placeholder for now)
	fmt.Printf("🚀 Server running on port %s\n", cfg.Port)

	// We will replace this with the actual HTTP router in the next step
	select {}
}
