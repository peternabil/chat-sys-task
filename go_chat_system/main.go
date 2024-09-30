package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	amqp "github.com/rabbitmq/amqp091-go"
	"github.com/redis/go-redis/v9"
)

var ctx = context.Background()

func main() {
	r := gin.Default()
	r.POST("/create-chat", createChat)
	r.POST("/create-message", createMessage)
	r.Run(":8080")
	defer cleanup()
}

var rdb = redis.NewClient(&redis.Options{
	Addr: os.Getenv("REDIS_CONN"),
})

var rabbitConn *amqp.Connection
var rabbitChannel *amqp.Channel

func init() {
	var err error
	err = godotenv.Load()
	if err != nil {
		fmt.Println("Error loading .env file")
	}
	fmt.Println(os.Getenv("RABBITMQ_CONN"))
	rabbitConn, err = amqp.Dial(os.Getenv("RABBITMQ_CONN"))
	if err != nil {
		log.Fatalf("Failed to connect to RabbitMQ: %v", err)
	}

	rabbitChannel, err = rabbitConn.Channel()
	if err != nil {
		log.Fatalf("Failed to open a RabbitMQ channel: %v", err)
	}

	_, err1 := rabbitChannel.QueueDeclare("chats_queue", true, false, false, false, nil)
	_, err2 := rabbitChannel.QueueDeclare("messages_queue", true, false, false, false, nil)
	if (err1 != nil) || (err2 != nil) {
		log.Fatalf("Failed to declare queues: %v, %v", err1.Error(), err2.Error())
	}
}

type ChatRequest struct {
	ApplicationToken string `json:"application_token"`
}

func createChat(c *gin.Context) {
	var req ChatRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}
	_, errToken := rdb.Get(ctx, "chats:"+req.ApplicationToken).Result()
	if errToken != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "There is no application with this token"})
		return
	}
	chatNumber, err := rdb.Incr(ctx, "chats:"+req.ApplicationToken).Result()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to increment chat count"})
		return
	}
	rdb.SAdd(ctx, "dirty:applications", req.ApplicationToken)
	chatData := map[string]interface{}{
		"application_token": req.ApplicationToken,
		"chat_number":       chatNumber,
	}
	sendToRabbitMQ("chats_queue", chatData)

	c.JSON(http.StatusCreated, gin.H{"chat_number": chatNumber})
}

type MessageRequest struct {
	ApplicationToken string `json:"application_token"`
	ChatID           int    `json:"chat_id"`
	Body             string `json:"body"`
}

func createMessage(c *gin.Context) {
	var req MessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}
	chatNumberStr, errApp := rdb.Get(ctx, "chats:"+req.ApplicationToken).Result()
	if errApp != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "There is no application with this token"})
		return
	}
	chatNumber, err := strconv.Atoi(chatNumberStr)
	if err != nil {
		fmt.Println("Error:", err)
	}
	if chatNumber < req.ChatID {
		c.JSON(http.StatusNotFound, gin.H{"error": "There is no chat with this id"})
		return
	}
	messageNumber, err := rdb.Incr(ctx, "messages:"+req.ApplicationToken+":chat:"+strconv.Itoa(req.ChatID)).Result()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to increment message count"})
		return
	}
	chatKey := req.ApplicationToken + ":chat:" + strconv.Itoa(req.ChatID)
	rdb.SAdd(ctx, "dirty:chats", chatKey)
	messageData := map[string]interface{}{
		"application_token": req.ApplicationToken,
		"chat_id":           req.ChatID,
		"message_number":    messageNumber,
		"body":              req.Body,
	}
	sendToRabbitMQ("messages_queue", messageData)

	c.JSON(http.StatusCreated, gin.H{"message_number": messageNumber})
}

func sendToRabbitMQ(queue string, data map[string]interface{}) {
	body, _ := json.Marshal(data)
	err := rabbitChannel.Publish("", queue, false, false, amqp.Publishing{
		ContentType: "application/json",
		Body:        body,
	})
	if err != nil {
		log.Printf("Failed to send to RabbitMQ: %v", err)
	}
}

func cleanup() {
	rabbitChannel.Close()
	rabbitConn.Close()
}
