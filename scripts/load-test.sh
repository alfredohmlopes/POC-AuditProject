#!/bin/bash
# Load Test Script for Audit Platform
# Uses curl for simple concurrency testing

set -e

# Configuration
GATEWAY_URL="${GATEWAY_URL:-http://localhost:9081}"
QUERY_API_URL="${QUERY_API_URL:-http://localhost:8091}"
EVENT_GATEWAY_URL="${EVENT_GATEWAY_URL:-http://localhost:8090}"
CONCURRENCY="${CONCURRENCY:-10}"
REQUESTS="${REQUESTS:-100}"

echo "=== Audit Platform Load Test ==="
echo "Gateway: $GATEWAY_URL"
echo "Query API: $QUERY_API_URL"
echo "Concurrency: $CONCURRENCY"
echo "Requests: $REQUESTS"

# Test 1: Query API - List Events
echo ""
echo "=== Test 1: GET /v1/events (List) ==="
START=$(date +%s%N)
for i in $(seq 1 $REQUESTS); do
    curl -s "$QUERY_API_URL/v1/events?limit=10" -H "X-Consumer-Name: audit-producer" > /dev/null &
    if [ $((i % CONCURRENCY)) -eq 0 ]; then wait; fi
done
wait
END=$(date +%s%N)
DURATION=$(echo "scale=2; ($END - $START) / 1000000000" | bc)
RPS=$(echo "scale=2; $REQUESTS / $DURATION" | bc)
echo "Duration: ${DURATION}s | RPS: $RPS"

# Test 2: Query API - Aggregations
echo ""
echo "=== Test 2: GET /v1/events/aggregations ==="
START=$(date +%s%N)
for i in $(seq 1 $REQUESTS); do
    curl -s "$QUERY_API_URL/v1/events/aggregations" -H "X-Consumer-Name: audit-producer" > /dev/null &
    if [ $((i % CONCURRENCY)) -eq 0 ]; then wait; fi
done
wait
END=$(date +%s%N)
DURATION=$(echo "scale=2; ($END - $START) / 1000000000" | bc)
RPS=$(echo "scale=2; $REQUESTS / $DURATION" | bc)
echo "Duration: ${DURATION}s | RPS: $RPS"

# Test 3: Event Ingestion
echo ""
echo "=== Test 3: POST /v1/events (Ingestion) ==="
START=$(date +%s%N)
for i in $(seq 1 $REQUESTS); do
    EVENT_JSON="{\"event_id\":\"load-test-$i\",\"event_date\":\"$(date +%Y-%m-%d)\",\"actor\":{\"id\":\"load-tester\"},\"action\":{\"name\":\"load-test\"},\"resource\":{\"type\":\"test\",\"id\":\"$i\"},\"result\":{\"success\":true}}"
    curl -s -X POST "$EVENT_GATEWAY_URL/v1/events" \
        -H "Content-Type: application/json" \
        -H "X-Consumer-Name: audit-producer" \
        -d "$EVENT_JSON" > /dev/null &
    if [ $((i % CONCURRENCY)) -eq 0 ]; then wait; fi
done
wait
END=$(date +%s%N)
DURATION=$(echo "scale=2; ($END - $START) / 1000000000" | bc)
RPS=$(echo "scale=2; $REQUESTS / $DURATION" | bc)
echo "Duration: ${DURATION}s | RPS: $RPS"

echo ""
echo "=== Load Test Complete ==="
