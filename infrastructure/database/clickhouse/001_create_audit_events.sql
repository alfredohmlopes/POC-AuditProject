-- ClickHouse Audit Events Table
-- Engine: ReplacingMergeTree for deduplication by event_id
-- Partition: Monthly by event_date for efficient pruning
-- Order: tenant_id, event_date, event_id for efficient queries

CREATE DATABASE IF NOT EXISTS audit;

CREATE TABLE IF NOT EXISTS audit.events
(
    event_id UUID,
    tenant_id String DEFAULT 'default_tenant',
    event_date Date,
    received_at DateTime64(3),
    
    -- Actor
    actor_id String,
    actor_type String,
    actor_email String,
    
    -- Action
    action_name LowCardinality(String),
    
    -- Resource
    resource_type LowCardinality(String),
    resource_id String,
    
    -- Result
    result_success Bool DEFAULT true,
    result_message String,
    
    -- Context
    context_ip String,
    context_user_agent String,
    
    -- Processing metadata
    processing_vector_node String,
    
    -- Raw event for full details
    raw_event String
)
ENGINE = ReplacingMergeTree()
PARTITION BY toYYYYMM(event_date)
ORDER BY (tenant_id, event_date, event_id)
TTL event_date + INTERVAL 90 DAY;

-- Create materialized view for hourly aggregates (for reconciliation)
CREATE MATERIALIZED VIEW IF NOT EXISTS audit.events_hourly_count
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(event_date)
ORDER BY (tenant_id, event_date, hour)
AS SELECT
    tenant_id,
    event_date,
    toHour(received_at) AS hour,
    count() AS event_count
FROM audit.events
GROUP BY tenant_id, event_date, hour;
