package main

import (
    "log"
    "senior-care-backend/config"
    "senior-care-backend/db"
    "senior-care-backend/handlers"
    "senior-care-backend/routes"
    "github.com/gin-gonic/gin"
)

func main() {
    cfg := config.Load()
    client := db.Connect(cfg.MongoURI)
    users  := db.GetCollection(client, cfg.DBName, "users")
    events := db.GetCollection(client, cfg.DBName, "events")

    authHandler  := handlers.NewAuthHandler(users, cfg.JWTSecret)
    eventHandler := handlers.NewEventHandler(events)

    r := gin.Default()
    r.GET("/health", func(c *gin.Context) {
        c.JSON(200, gin.H{"status": "ok"})
    })

    routes.Setup(r, authHandler, eventHandler, cfg.JWTSecret)

    log.Printf("서버 시작: :%s", cfg.Port)
    r.Run(":" + cfg.Port)
}