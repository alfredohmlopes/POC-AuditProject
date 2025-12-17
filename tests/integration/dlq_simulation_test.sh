#!/bin/bash
# DLQ Failure Simulation Test
# Tests that malformed events are routed to the Dead Letter Queue

set -e

BASE_URL="${BASE_URL:-http://localhost:9080}"
API_KEY="${API_KEY:-poc-audit-api-key-2024}"

echo "========================================"
echo "       DLQ FAILURE SIMULATION TEST"
echo "========================================"

# Test 1: Missing required field (actor.id)
echo ""
echo "Test 1: Missing actor.id field"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/v1/events" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  -d '{
    "actor": {"type": "user"},
    "action": {"name": "test.event"},
    "resource": {"type": "test", "id": "1"}
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "400" ]; then
  echo "✓ Correctly rejected with 400: $BODY"
else
  echo "✗ Expected 400, got $HTTP_CODE"
fi

# Test 2: Missing action.name
echo ""
echo "Test 2: Missing action.name field"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/v1/events" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  -d '{
    "actor": {"id": "user-1"},
    "resource": {"type": "test", "id": "1"}
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" = "400" ]; then
  echo "✓ Correctly rejected with 400"
else
  echo "✗ Expected 400, got $HTTP_CODE"
fi

# Test 3: Invalid JSON
echo ""
echo "Test 3: Invalid JSON payload"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/v1/events" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  -d 'not valid json')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" = "400" ]; then
  echo "✓ Correctly rejected with 400"
else
  echo "✗ Expected 400, got $HTTP_CODE"
fi

# Test 4: Valid event (should succeed)
echo ""
echo "Test 4: Valid event (should succeed)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/v1/events" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  -d '{
    "actor": {"id": "user-1", "type": "user"},
    "action": {"name": "dlq.test.valid"},
    "resource": {"type": "test", "id": "1"}
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "202" ]; then
  echo "✓ Accepted with 202: $BODY"
else
  echo "✗ Expected 202, got $HTTP_CODE"
fi

# Check DLQ topic for messages  
echo ""
echo "========================================"
echo "Checking DLQ topic for messages..."
echo "(Run this manually to verify DLQ):"
echo "kubectl exec -n redpanda redpanda-0 -- rpk topic consume audit.events.dlq --num 5"
echo "========================================"
