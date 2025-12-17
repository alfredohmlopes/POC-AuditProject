# clickhouse-storage Specification

## Purpose
TBD - created by archiving change implement-storage-pipeline. Update Purpose after archive.
## Requirements
### Requirement: ClickHouse Bulk Insert
The system SHALL persist events to ClickHouse using bulk HTTP inserts.

#### Scenario: Events are batched and inserted
- **WHEN** batch reaches 10,000 events OR 5 seconds timeout
- **THEN** events are bulk inserted to ClickHouse `audit_events` table
- **AND** LZ4 compression is enabled

### Requirement: ClickHouse Table Schema
The system SHALL use ReplacingMergeTree for deduplication.

#### Scenario: Table is created with correct schema
- **WHEN** table `audit_events` is created
- **THEN** engine is `ReplacingMergeTree`
- **AND** order by is `(tenant_id, event_date, event_id)`

### Requirement: ClickHouse Retry
The system SHALL retry failed inserts with exponential backoff.

#### Scenario: Transient failure triggers retry
- **WHEN** ClickHouse insert fails with transient error
- **THEN** up to 3 retries occur with delays 1s, 2s, 4s
- **AND** event goes to DLQ after all retries fail

