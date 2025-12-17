## ADDED Requirements

### Requirement: OpenSearch Bulk Index
The system SHALL index events to OpenSearch using bulk API.

#### Scenario: Events are batched and indexed
- **WHEN** batch reaches 5,000 documents OR 5 seconds timeout
- **THEN** events are bulk indexed to OpenSearch
- **AND** index name follows pattern `audit-events-YYYY-MM-DD`

### Requirement: OpenSearch Index Template
The system SHALL use index template for consistent mapping.

#### Scenario: Template is applied to new indices
- **WHEN** new daily index is created
- **THEN** template mapping is applied

### Requirement: OpenSearch Retry
The system SHALL retry failed index operations.

#### Scenario: Transient failure triggers retry
- **WHEN** OpenSearch index fails with transient error
- **THEN** up to 3 retries occur with exponential backoff
- **AND** event goes to DLQ after all retries fail

### Requirement: Index Lifecycle Management
The system SHALL apply ISM policy for automatic index management.

#### Scenario: Old indices are deleted
- **WHEN** index is older than 7 days
- **THEN** index is deleted
- **AND** force merge is applied after 1 day
