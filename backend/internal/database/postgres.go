package database

import (
	"context"
	"log"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func ConnectDB(dbUrl string) *pgxpool.Pool {
	// Parse the connection string (supports both URL and Key-Value formats)
	config, err := pgxpool.ParseConfig(dbUrl)
	if err != nil {
		log.Fatalf("Unable to parse DB URL: %v\n", err)
	}

	// Force disable TLS for local development
	// (since your local Postgres isn't configured for SSL)
	config.ConnConfig.TLSConfig = nil

	// Set connection pool settings
	config.MaxConns = 25
	config.MinConns = 5
	config.MaxConnIdleTime = time.Minute * 15

	// Create the connection pool
	pool, err := pgxpool.NewWithConfig(context.Background(), config)
	if err != nil {
		log.Fatalf("Unable to create connection pool: %v\n", err)
	}

	// Ping the database to verify connection
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("Database unreachable: %v\n", err)
	}

	log.Println("✅ Successfully connected to PostgreSQL database!")
	return pool
}
