package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type EventType string

const (
	EventFallDetected EventType = "fall_detected"
	EventLyingDown    EventType = "lying_down"
)

type FallEvent struct {
	ID         primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	ElderID    string             `bson:"elder_id"      json:"elder_id"`
	EventType  EventType          `bson:"event_type"    json:"event_type"`
	Action     string             `bson:"action"        json:"action"`
	Confidence float64            `bson:"confidence"    json:"confidence"`
	Location   string             `bson:"location"      json:"location"`
	OccurredAt time.Time          `bson:"occurred_at"   json:"occurred_at"`
	CreatedAt  time.Time          `bson:"created_at"    json:"created_at"`
	Resolved   bool               `bson:"resolved"      json:"resolved"`
}

type FallEventRequest struct {
	ElderID    string    `json:"elder_id"   binding:"required"`
	EventType  EventType `json:"event_type" binding:"required"`
	Action     string    `json:"action"     binding:"required"`
	Confidence float64   `json:"confidence"`
	Location   string    `json:"location"`
	OccurredAt time.Time `json:"occurred_at"`
}
