package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	Port               string
	DBUrl              string
	JWTAccessSecret    string
	JWTRefreshSecret   string
	JWTAccessTTL       string
	JWTRefreshTTL      string
	CORSAllowedOrigins string
}

func LoadConfig() *Config {
	// Try current directory first, then fall back to two folders up
	if err := godotenv.Load(); err != nil {
		if err2 := godotenv.Load("../../.env"); err2 != nil {
			log.Println("No .env file found, using environment variables")
		}
	}

	return &Config{
		Port:               getEnv("APP_PORT", "8080"),
		DBUrl:              getEnv("DB_URL", ""),
		JWTAccessSecret:    getEnv("JWT_ACCESS_SECRET", "dev-access-secret"),
		JWTRefreshSecret:   getEnv("JWT_REFRESH_SECRET", "dev-refresh-secret"),
		JWTAccessTTL:       getEnv("JWT_ACCESS_TTL", "15m"),
		JWTRefreshTTL:      getEnv("JWT_REFRESH_TTL", "720h"),
		CORSAllowedOrigins: getEnv("CORS_ALLOWED_ORIGINS", "*"),
	}
}

func getEnv(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok {
		return v
	}
	return fallback
}
