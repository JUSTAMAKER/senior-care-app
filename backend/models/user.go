package models

import (
    "time"
    "go.mongodb.org/mongo-driver/bson/primitive"
)

type AuthProvider string
type UserRole string

const (
    ProviderEmail  AuthProvider = "email"
    ProviderGoogle AuthProvider = "google"
)

const (
    RoleCaregiver UserRole = "caregiver"
    RoleElder     UserRole = "elder"
)

type User struct {
    ID           primitive.ObjectID `bson:"_id,omitempty"    json:"id"`
    Name         string             `bson:"name"             json:"name"`
    Phone        string             `bson:"phone"            json:"phone"`
    Email        string             `bson:"email"            json:"email"`
    PasswordHash string             `bson:"password_hash"    json:"-"`
    Provider     AuthProvider       `bson:"provider"         json:"provider"`
    Role         UserRole           `bson:"role"             json:"role"`
    GoogleID     string             `bson:"google_id"        json:"google_id,omitempty"`
    CreatedAt    time.Time          `bson:"created_at"       json:"created_at"`
    UpdatedAt    time.Time          `bson:"updated_at"       json:"updated_at"`
}

// 회원가입 요청
type SignupRequest struct {
    Name     string   `json:"name"     binding:"required"`
    Phone    string   `json:"phone"    binding:"required"`
    Email    string   `json:"email"    binding:"required,email"`
    Password string   `json:"password" binding:"required,min=8"`
    Role     UserRole `json:"role"     binding:"required"`
}

// 로그인 요청
type LoginRequest struct {
    Email    string `json:"email"    binding:"required,email"`
    Password string `json:"password" binding:"required"`
}

// Google 로그인 요청
type GoogleAuthRequest struct {
    IDToken string `json:"id_token" binding:"required"`
    Name    string `json:"name"     binding:"required"`
    Phone   string `json:"phone"`
}

// 응답 토큰
type AuthResponse struct {
    AccessToken  string `json:"access_token"`
    RefreshToken string `json:"refresh_token"`
    User         User   `json:"user"`
}