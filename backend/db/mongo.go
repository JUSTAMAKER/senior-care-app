package db

import (
    "context"
    "log"
    "time"
    "go.mongodb.org/mongo-driver/mongo"
    "go.mongodb.org/mongo-driver/mongo/options"
)

var Client *mongo.Client

func Connect(uri string) *mongo.Client {
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()

    client, err := mongo.Connect(ctx, options.Client().ApplyURI(uri))
    if err != nil {
        log.Fatal("MongoDB 연결 실패:", err)
    }

    if err := client.Ping(ctx, nil); err != nil {
        log.Fatal("MongoDB ping 실패:", err)
    }

    log.Println("MongoDB 연결 성공")
    Client = client
    return client
}

func GetCollection(client *mongo.Client, dbName, colName string) *mongo.Collection {
    return client.Database(dbName).Collection(colName)
}