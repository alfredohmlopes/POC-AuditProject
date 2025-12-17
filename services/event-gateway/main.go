package main

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/google/uuid"
)

// Event represents an incoming audit event
type Event struct {
	Actor     map[string]interface{} `json:"actor"`
	Action    map[string]interface{} `json:"action"`
	Resource  map[string]interface{} `json:"resource"`
	Timestamp string                 `json:"timestamp,omitempty"`
	Result    map[string]interface{} `json:"result,omitempty"`
	Context   map[string]interface{} `json:"context,omitempty"`
	TenantID  string                 `json:"tenant_id,omitempty"`
}

// EnrichedEvent extends Event with generated fields
type EnrichedEvent struct {
	Event
	EventID    string `json:"event_id"`
	ReceivedAt string `json:"received_at"`
}

// SingleResponse is the response for single event ingestion
type SingleResponse struct {
	EventID    string `json:"event_id"`
	ReceivedAt string `json:"received_at"`
}

// BatchRequest is the incoming batch request format
type BatchRequest struct {
	Events []Event `json:"events"`
}

// BatchEventResponse represents a single event result in batch
type BatchEventResponse struct {
	EventID string `json:"event_id"`
	Status  string `json:"status"`
}

// BatchResponse is the response for batch event ingestion
type BatchResponse struct {
	Accepted int                  `json:"accepted"`
	Rejected int                  `json:"rejected"`
	Events   []BatchEventResponse `json:"events"`
}

var vectorURL string

func init() {
	vectorURL = os.Getenv("VECTOR_URL")
	if vectorURL == "" {
		vectorURL = "http://vector.vector.svc.cluster.local:8080"
	}
}

// generateUUIDv7 generates a time-ordered UUID (v7-like using v4 for simplicity)
func generateUUIDv7() string {
	return uuid.New().String()
}

// forwardToVector sends event to Vector asynchronously
func forwardToVector(event EnrichedEvent) {
	go func() {
		data, err := json.Marshal(event)
		if err != nil {
			log.Printf("Error marshaling event: %v", err)
			return
		}
		resp, err := http.Post(vectorURL, "application/json", bytes.NewReader(data))
		if err != nil {
			log.Printf("Error forwarding to Vector: %v", err)
			return
		}
		defer resp.Body.Close()
		if resp.StatusCode >= 400 {
			log.Printf("Vector returned error: %d", resp.StatusCode)
		}
	}()
}

func main() {
	app := fiber.New(fiber.Config{
		DisableStartupMessage: true,
	})

	app.Use(logger.New())

	// Health check
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "healthy"})
	})

	// Single event endpoint
	app.Post("/v1/events", func(c *fiber.Ctx) error {
		var event Event
		if err := c.BodyParser(&event); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid JSON"})
		}

		// Validate required fields
		if event.Actor == nil || event.Actor["id"] == nil {
			return c.Status(400).JSON(fiber.Map{"error": "actor.id is required"})
		}
		if event.Action == nil || event.Action["name"] == nil {
			return c.Status(400).JSON(fiber.Map{"error": "action.name is required"})
		}
		if event.Resource == nil || event.Resource["type"] == nil || event.Resource["id"] == nil {
			return c.Status(400).JSON(fiber.Map{"error": "resource.type and resource.id are required"})
		}

		// Generate metadata
		eventID := generateUUIDv7()
		receivedAt := time.Now().UTC().Format(time.RFC3339Nano)

		// Create enriched event
		enriched := EnrichedEvent{
			Event:      event,
			EventID:    eventID,
			ReceivedAt: receivedAt,
		}

		// Forward to Vector asynchronously
		forwardToVector(enriched)

		// Return 202 immediately
		return c.Status(202).JSON(SingleResponse{
			EventID:    eventID,
			ReceivedAt: receivedAt,
		})
	})

	// Batch event endpoint
	app.Post("/v1/events/batch", func(c *fiber.Ctx) error {
		var events []Event

		// Try parsing as array first
		if err := c.BodyParser(&events); err != nil {
			// Try parsing as BatchRequest
			var batchReq BatchRequest
			if err := json.Unmarshal(c.Body(), &batchReq); err != nil {
				return c.Status(400).JSON(fiber.Map{"error": "Invalid JSON: expected array or {events: [...]}"})
			}
			events = batchReq.Events
		}

		if len(events) == 0 {
			return c.Status(400).JSON(fiber.Map{"error": "No events provided"})
		}

		if len(events) > 1000 {
			return c.Status(400).JSON(fiber.Map{"error": "Maximum 1000 events per batch"})
		}

		var results []BatchEventResponse
		accepted := 0
		rejected := 0
		receivedAt := time.Now().UTC().Format(time.RFC3339Nano)

		for _, event := range events {
			// Validate required fields
			if event.Actor == nil || event.Actor["id"] == nil ||
				event.Action == nil || event.Action["name"] == nil ||
				event.Resource == nil || event.Resource["type"] == nil || event.Resource["id"] == nil {
				rejected++
				results = append(results, BatchEventResponse{
					EventID: "",
					Status:  "rejected",
				})
				continue
			}

			eventID := generateUUIDv7()
			enriched := EnrichedEvent{
				Event:      event,
				EventID:    eventID,
				ReceivedAt: receivedAt,
			}

			forwardToVector(enriched)
			accepted++
			results = append(results, BatchEventResponse{
				EventID: eventID,
				Status:  "accepted",
			})
		}

		return c.Status(202).JSON(BatchResponse{
			Accepted: accepted,
			Rejected: rejected,
			Events:   results,
		})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Event Gateway starting on port %s", port)
	log.Fatal(app.Listen(":" + port))
}
