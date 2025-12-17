# Implement Storage Pipeline (Epic 03)

## Summary
Implement consumers that read from Redpanda and persist data to ClickHouse (analytics) and OpenSearch (search), ensuring consistency and performance.

## Why
Events are being produced to Redpanda (Epic 02) but are not yet consumed or stored. This creates a gap where:
- Analytical queries cannot be run
- Full-text search is not available
- Data is ephemeral (topic retention limits)
Without this change, the audit platform cannot provide value to end users.

## Motivation
Events are being produced to Redpanda (Epic 02). This change implements the consumption and storage layer to enable:
- Analytical queries via ClickHouse
- Full-text search via OpenSearch
- Data durability with retry and dead letter queue

## Scope
| In Scope | Out of Scope |
|----------|--------------|
| Vector consumer from Redpanda | Query API (Epic 04) |
| ClickHouse sink with batching | UI dashboards |
| OpenSearch sink with daily indices | Complex transformations |
| Dead letter queue for failures | Multi-region replication |
| Index lifecycle management | Long-term archival (S3) |
| Data quality reconciliation | Real-time streaming |

## Success Criteria
- [ ] Consumer lag < 1 minute in steady state
- [ ] Zero data loss between Redpanda and stores
- [ ] DLQ capturing failed events
- [ ] Metrics and alerts configured
- [ ] Daily index rotation in OpenSearch
- [ ] Reconciliation dashboard showing ingestion metrics

## Related Specs
- `event-consumer`: Vector consumer configuration
- `clickhouse-storage`: ClickHouse persistence
- `opensearch-storage`: OpenSearch indexing
- `dead-letter-queue`: DLQ handling
- `index-lifecycle`: OpenSearch ISM policies
- `data-quality`: Reconciliation and quality checks
