package handlers

import (
    "context"
    "encoding/json"
    "fmt"
    "net/http"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
    "go.mongodb.org/mongo-driver/bson"
    "go.mongodb.org/mongo-driver/bson/primitive"
    "go.mongodb.org/mongo-driver/mongo"
    "golang.org/x/crypto/bcrypt"

    "senior-care-backend/middleware"
    "senior-care-backend/models"
)

type AuthHandler struct {
    users     *mongo.Collection
    jwtSecret string
}

func NewAuthHandler(users *mongo.Collection, jwtSecret string) *AuthHandler {
    return &AuthHandler{users: users, jwtSecret: jwtSecret}
}

// POST /auth/signup
func (h *AuthHandler) Signup(c *gin.Context) {
    var req models.SignupRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    // 이메일 중복 확인
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    var existing models.User
    err := h.users.FindOne(ctx, bson.M{"email": req.Email}).Decode(&existing)
    if err == nil {
        c.JSON(http.StatusConflict, gin.H{"error": "이미 사용 중인 이메일입니다"})
        return
    }

    // 비밀번호 해시
    hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "서버 오류"})
        return
    }

    // 유저 저장
    role := req.Role
    if role != models.RoleCaregiver && role != models.RoleElder {
        role = models.RoleCaregiver
    }
    now := time.Now()
    user := models.User{
        ID:           primitive.NewObjectID(),
        Name:         req.Name,
        Phone:        req.Phone,
        Email:        req.Email,
        PasswordHash: string(hash),
        Provider:     models.ProviderEmail,
        Role:         role,
        CreatedAt:    now,
        UpdatedAt:    now,
    }

    if _, err := h.users.InsertOne(ctx, user); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "회원가입 실패"})
        return
    }

    // JWT 발급
    access, refresh, err := h.generateTokens(user.ID.Hex())
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "토큰 생성 실패"})
        return
    }

    c.JSON(http.StatusCreated, models.AuthResponse{
        AccessToken:  access,
        RefreshToken: refresh,
        User:         user,
    })
}

// POST /auth/login
func (h *AuthHandler) Login(c *gin.Context) {
    var req models.LoginRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    var user models.User
    err := h.users.FindOne(ctx, bson.M{"email": req.Email}).Decode(&user)
    if err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "이메일 또는 비밀번호가 올바르지 않습니다"})
        return
    }

    if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "이메일 또는 비밀번호가 올바르지 않습니다"})
        return
    }

    access, refresh, err := h.generateTokens(user.ID.Hex())
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "토큰 생성 실패"})
        return
    }

    c.JSON(http.StatusOK, models.AuthResponse{
        AccessToken:  access,
        RefreshToken: refresh,
        User:         user,
    })
}

func (h *AuthHandler) generateTokens(userID string) (string, string, error) {
    // Access Token (1시간)
    access := jwt.NewWithClaims(jwt.SigningMethodHS256, &middleware.Claims{
        UserID: userID,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour)),
        },
    })
    accessStr, err := access.SignedString([]byte(h.jwtSecret))
    if err != nil {
        return "", "", err
    }

    // Refresh Token (7일)
    refresh := jwt.NewWithClaims(jwt.SigningMethodHS256, &middleware.Claims{
        UserID: userID,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(time.Now().Add(7 * 24 * time.Hour)),
        },
    })
    refreshStr, err := refresh.SignedString([]byte(h.jwtSecret))
    if err != nil {
        return "", "", err
    }

    return accessStr, refreshStr, nil
}

// POST /auth/google
func (h *AuthHandler) GoogleLogin(c *gin.Context) {
    var req models.GoogleAuthRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    // Google Token 검증
    payload, err := verifyGoogleToken(req.IDToken)
    if err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "유효하지 않은 Google 토큰"})
        return
    }

    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    // 기존 유저 조회
    var user models.User
    err = h.users.FindOne(ctx, bson.M{"email": payload.Email}).Decode(&user)

    if err == mongo.ErrNoDocuments {
        // 신규 유저 생성
        now := time.Now()
        user = models.User{
            ID:        primitive.NewObjectID(),
            Name:      req.Name,
            Phone:     req.Phone,
            Email:     payload.Email,
            GoogleID:  payload.Subject,
            Provider:  models.ProviderGoogle,
            CreatedAt: now,
            UpdatedAt: now,
        }
        if _, err := h.users.InsertOne(ctx, user); err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": "회원가입 실패"})
            return
        }
    } else if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "서버 오류"})
        return
    }

    // JWT 발급
    access, refresh, err := h.generateTokens(user.ID.Hex())
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "토큰 생성 실패"})
        return
    }

    c.JSON(http.StatusOK, models.AuthResponse{
        AccessToken:  access,
        RefreshToken: refresh,
        User:         user,
    })
}

// Google ID Token 검증
type GooglePayload struct {
    Email   string
    Subject string
    Name    string
}

func verifyGoogleToken(idToken string) (*GooglePayload, error) {
    resp, err := http.Get("https://oauth2.googleapis.com/tokeninfo?id_token=" + idToken)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    if resp.StatusCode != 200 {
        return nil, fmt.Errorf("invalid token")
    }

    var result map[string]interface{}
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return nil, err
    }

    return &GooglePayload{
        Email:   result["email"].(string),
        Subject: result["sub"].(string),
        Name:    result["name"].(string),
    }, nil
}