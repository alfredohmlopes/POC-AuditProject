package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"testing"
	"time"
)

var baseURL = "http://localhost:9080"
var apiKey = "poc-audit-api-key-2024"

func init() {
	if url := os.Getenv("BASE_URL"); url != "" {
		baseURL = url
	}
	if key := os.Getenv("API_KEY"); key != "" {
		apiKey = key
	}
}

func TestSingleEvent_ValidPayload(t *testing.T) {
	payload := map[string]interface{}{
		"actor":    map[string]interface{}{"id": "user-123", "type": "user"},
		"action":   map[string]interface{}{"name": "user.created"},
		"resource": map[string]interface{}{"type": "user", "id": "user-456"},
	}
	body, _ := json.Marshal(payload)

	req, _ := http.NewRequest("POST", baseURL+"/v1/events", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-API-Key", apiKey)

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 202 {
		t.Errorf("Expected 202, got %d", resp.StatusCode)
	}

	var result map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&result)

	if result["event_id"] == nil {
		t.Error("Response missing event_id")
	}
	if result["received_at"] == nil {
		t.Error("Response missing received_at")
	}
	fmt.Printf("✓ Single event: event_id=%s\n", result["event_id"])
}

func TestSingleEvent_MissingFields(t *testing.T) {
	payload := map[string]interface{}{
		"actor": map[string]interface{}{"id": "user-123"},
		// Missing action and resource
	}
	body, _ := json.Marshal(payload)

	req, _ := http.NewRequest("POST", baseURL+"/v1/events", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-API-Key", apiKey)

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 400 {
		t.Errorf("Expected 400, got %d", resp.StatusCode)
	}
	fmt.Println("✓ Missing fields returns 400")
}

func TestSingleEvent_MissingAPIKey(t *testing.T) {
	payload := map[string]interface{}{
		"actor":    map[string]interface{}{"id": "user-123"},
		"action":   map[string]interface{}{"name": "test"},
		"resource": map[string]interface{}{"type": "t", "id": "1"},
	}
	body, _ := json.Marshal(payload)

	req, _ := http.NewRequest("POST", baseURL+"/v1/events", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	// No API Key

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 401 {
		t.Errorf("Expected 401, got %d", resp.StatusCode)
	}
	fmt.Println("✓ Missing API key returns 401")
}

func TestBatchEvents_ValidPayload(t *testing.T) {
	payload := []map[string]interface{}{
		{
			"actor":    map[string]interface{}{"id": "u1"},
			"action":   map[string]interface{}{"name": "batch.1"},
			"resource": map[string]interface{}{"type": "t", "id": "1"},
		},
		{
			"actor":    map[string]interface{}{"id": "u2"},
			"action":   map[string]interface{}{"name": "batch.2"},
			"resource": map[string]interface{}{"type": "t", "id": "2"},
		},
	}
	body, _ := json.Marshal(payload)

	req, _ := http.NewRequest("POST", baseURL+"/v1/events/batch", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-API-Key", apiKey)

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 202 {
		t.Errorf("Expected 202, got %d", resp.StatusCode)
	}

	var result map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&result)

	accepted := int(result["accepted"].(float64))
	rejected := int(result["rejected"].(float64))

	if accepted != 2 {
		t.Errorf("Expected 2 accepted, got %d", accepted)
	}
	if rejected != 0 {
		t.Errorf("Expected 0 rejected, got %d", rejected)
	}
	fmt.Printf("✓ Batch: accepted=%d, rejected=%d\n", accepted, rejected)
}

func TestBatchEvents_PartialSuccess(t *testing.T) {
	payload := []map[string]interface{}{
		{
			"actor":    map[string]interface{}{"id": "u1"},
			"action":   map[string]interface{}{"name": "valid"},
			"resource": map[string]interface{}{"type": "t", "id": "1"},
		},
		{
			"actor": map[string]interface{}{"id": "u2"},
			// Missing action and resource - should be rejected
		},
	}
	body, _ := json.Marshal(payload)

	req, _ := http.NewRequest("POST", baseURL+"/v1/events/batch", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-API-Key", apiKey)

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 202 {
		t.Errorf("Expected 202, got %d", resp.StatusCode)
	}

	var result map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&result)

	accepted := int(result["accepted"].(float64))
	rejected := int(result["rejected"].(float64))

	if accepted != 1 {
		t.Errorf("Expected 1 accepted, got %d", accepted)
	}
	if rejected != 1 {
		t.Errorf("Expected 1 rejected, got %d", rejected)
	}
	fmt.Printf("✓ Partial success: accepted=%d, rejected=%d\n", accepted, rejected)
}
