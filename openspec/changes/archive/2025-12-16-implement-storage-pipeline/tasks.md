# Tasks - Implement Storage Pipeline

## Phase 1: Vector Consumer Setup (E3.S1)
- [x] Configure Vector Kafka source to consume from `audit.events.v1`
- [x] Set consumer group `audit-consumer-group`
- [x] Configure auto-offset commit
- [x] Expose lag metrics via Prometheus
- [x] Deploy and verify consumer is reading events

## Phase 2: ClickHouse Sink (E3.S2)
- [x] Create ClickHouse table `audit_events` with ReplacingMergeTree
- [x] Configure Vector ClickHouse sink with HTTP bulk insert
- [x] Configure batching: 10K events or 5s timeout
- [x] Enable gzip compression (lz4 not supported by Vector)
- [x] Verify events are persisted in ClickHouse
- [x] Add retry logic (3 attempts, exponential backoff)

## Phase 3: OpenSearch Sink (E3.S3)
- [x] Create OpenSearch index template for `audit-events-*`
- [x] Configure Vector Elasticsearch sink pointing to OpenSearch
- [x] Configure batching: 5K docs or 5s timeout
- [x] Implement daily index pattern `audit-events-YYYY-MM-DD`
- [x] Verify events are indexed in OpenSearch
- [x] Add retry logic

## Phase 4: Dead Letter Queue (E3.S4)
- [x] Create Redpanda topic `audit.events.dlq`
- [x] Configure DLQ sink in Vector for failed events
- [x] Route parsing failures to DLQ
- [x] Route insert failures (after retries) to DLQ
- [x] Create Prometheus alert for DLQ messages
- [x] Document reprocessing procedure

## Phase 5: Index Lifecycle Management (E3.S5)
- [x] Create ISM policy in OpenSearch
- [x] Configure rollover: daily
- [x] Configure force merge: after 1 day
- [x] Configure delete: after 7 days
- [ ] Optionally configure snapshot before delete
- [x] Apply policy to `audit-events-*` indices

## Phase 6: Data Quality & Reconciliation (E3.S6)
- [x] Create ClickHouse query for hourly event counts
- [ ] Create reconciliation dashboard comparing Redpanda offsets vs ClickHouse counts
- [ ] Create alert if difference > 1%
- [ ] Create duplicates detection query
- [ ] Document data quality procedures

## Verification
- [x] End-to-end test: send event → verify in ClickHouse → verify in OpenSearch
- [x] Simulate failure: verify DLQ receives failed events
- [x] Load test: verify consumer lag < 1 minute at 5000 events/s
- [x] Verify zero data loss with reconciliation query
