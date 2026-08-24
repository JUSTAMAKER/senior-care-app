package config

import (
    "log"
    "os"
    "github.com/joho/godotenv"
)

type Config struct {
    MongoURI   string
    DBName     string
    JWTSecret  string
    Port       string
}

func Load() *Config {
    if err := godotenv.Load(); err != nil {
        log.Println(".env 파일 없음, 환경변수 직접 사용")
    }
    return &Config{
        MongoURI:  getEnv("MONGO_URI", "mongodb://localhost:27017"),
        DBName:    getEnv("DB_NAME", "senior_care"),
        JWTSecret: getEnv("JWT_SECRET", "dev-secret-change-in-prod"),
        Port:      getEnv("PORT", "8080"),
    }
}

func getEnv(key, fallback string) string {
    if v := os.Getenv(key); v != "" {
        return v
    }
    return fallback
}