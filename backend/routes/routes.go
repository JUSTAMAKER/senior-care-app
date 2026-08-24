package routes

import (
    "github.com/gin-gonic/gin"
    "senior-care-backend/handlers"
    "senior-care-backend/middleware"
)

func Setup(r *gin.Engine, auth *handlers.AuthHandler, event *handlers.EventHandler, jwtSecret string) {
    // 인증 불필요
    public := r.Group("/auth")
    {
        public.POST("/signup", auth.Signup)
        public.POST("/login",  auth.Login)
        public.POST("/google", auth.GoogleLogin)
    }

    // Python AI 서버에서 호출 (내부 네트워크 전용)
    r.POST("/events/fall", event.ReceiveFallEvent)

    // 인증 필요
    protected := r.Group("/api")
    protected.Use(middleware.JWTAuth(jwtSecret))
    {
        protected.GET("/me", func(c *gin.Context) {
            c.JSON(200, gin.H{"user_id": c.GetString("user_id")})
        })
        protected.GET("/events",          event.GetEvents)
        protected.PATCH("/events/:id/resolve", event.ResolveEvent)
    }
}