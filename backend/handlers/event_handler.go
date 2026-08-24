package handlers

import (
	"context"
	"log"
	"net/http"
	"time"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"google.golang.org/api/option"

	"senior-care-backend/models"
)

type EventHandler struct {
	events *mongo.Collection
}

func NewEventHandler(events *mongo.Collection) *EventHandler {
	return &EventHandler{events: events}
}

// POST /events/fall  — Python AI 서버에서 호출
func (h *EventHandler) ReceiveFallEvent(c *gin.Context) {
	var req models.FallEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	occurredAt := req.OccurredAt
	if occurredAt.IsZero() {
		occurredAt = time.Now()
	}

	event := models.FallEvent{
		ID:         primitive.NewObjectID(),
		ElderID:    req.ElderID,
		EventType:  req.EventType,
		Action:     req.Action,
		Confidence: req.Confidence,
		Location:   req.Location,
		OccurredAt: occurredAt,
		CreatedAt:  time.Now(),
		Resolved:   false,
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if _, err := h.events.InsertOne(ctx, event); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "이벤트 저장 실패"})
		return
	}

	log.Printf("[낙상 이벤트] elder=%s action=%s confidence=%.1f%%",
		req.ElderID, req.Action, req.Confidence*100)

	// FCM 푸시 알림 전송
	go sendFCMNotification(req)

	c.JSON(http.StatusCreated, gin.H{"message": "이벤트 수신 완료", "id": event.ID.Hex()})
}

// GET /events?elder_id=xxx  — Flutter 앱에서 이벤트 목록 조회
func (h *EventHandler) GetEvents(c *gin.Context) {
	elderID := c.Query("elder_id")

	filter := bson.M{}
	if elderID != "" {
		filter["elder_id"] = elderID
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	opts := options.Find().SetSort(bson.D{{Key: "occurred_at", Value: -1}}).SetLimit(50)
	cursor, err := h.events.Find(ctx, filter, opts)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "조회 실패"})
		return
	}

	var events []models.FallEvent
	if err := cursor.All(ctx, &events); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "데이터 파싱 실패"})
		return
	}

	c.JSON(http.StatusOK, events)
}

// PATCH /events/:id/resolve  — 보호자가 확인 완료 처리
func (h *EventHandler) ResolveEvent(c *gin.Context) {
	id, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "잘못된 ID"})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err = h.events.UpdateOne(ctx,
		bson.M{"_id": id},
		bson.M{"$set": bson.M{"resolved": true}},
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "업데이트 실패"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "확인 완료"})
}

// ─────────────────────────────────────────
// FCM 푸시 알림 (Firebase Admin SDK)
// ─────────────────────────────────────────
func sendFCMNotification(req models.FallEventRequest) {
	ctx := context.Background()

	app, err := firebase.NewApp(ctx, nil,
		option.WithCredentialsFile("config/firebase-adminsdk.json"),
	)
	if err != nil {
		log.Printf("[FCM] Firebase 초기화 실패: %v", err)
		return
	}

	client, err := app.Messaging(ctx)
	if err != nil {
		log.Printf("[FCM] Messaging 클라이언트 실패: %v", err)
		return
	}

	title := "⚠️ 낙상 감지"
	body := req.Action + " 감지됨 · " + req.Location
	if req.EventType == models.EventLyingDown {
		title = "장시간 누워있음"
		body = req.Location + "에서 장시간 무응답 상태"
	}

	message := &messaging.Message{
		Topic: "senior_care_alerts",
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: map[string]string{
			"elder_id":   req.ElderID,
			"event_type": string(req.EventType),
			"action":     req.Action,
			"location":   req.Location,
		},
		Android: &messaging.AndroidConfig{
			Priority: "high",
		},
	}

	resp, err := client.Send(ctx, message)
	if err != nil {
		log.Printf("[FCM] 전송 실패: %v", err)
		return
	}
	log.Printf("[FCM] 전송 완료: %s", resp)
}
