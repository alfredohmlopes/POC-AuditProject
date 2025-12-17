## ADDED Requirements

### Requirement: Vector Kafka Consumer
The system SHALL consume events from Redpanda topic `audit.events.v1` using Vector's Kafka source.

#### Scenario: Consumer reads events from Redpanda
- **WHEN** events are produced to `audit.events.v1`
- **THEN** Vector consumes events with consumer group `audit-consumer-group`
- **AND** auto-offset commit is enabled

### Requirement: Consumer Lag Monitoring
The system SHALL expose consumer lag metrics for monitoring.

#### Scenario: Lag metric is scraped by Prometheus
- **WHEN** Prometheus scrapes `/metrics` endpoint
- **THEN** metric `vector_kafka_consumer_lag` is available

### Requirement: Consumer Health Check
The system SHALL expose health status based on consumer lag.

#### Scenario: Unhealthy when lag is too high
- **WHEN** consumer lag exceeds 60 seconds
- **THEN** health endpoint returns unhealthy status
