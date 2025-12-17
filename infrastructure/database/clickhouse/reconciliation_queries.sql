-- ClickHouse Reconciliation Query
-- Compares event counts per hour between Redpanda offsets and stored events

-- Hourly event counts stored in ClickHouse
SELECT 
    event_date,
    toHour(received_at) AS hour,
    tenant_id,
    count() AS event_count,
    min(received_at) AS first_event,
    max(received_at) AS last_event
FROM audit.events
WHERE event_date >= today() - 1
GROUP BY event_date, hour, tenant_id
ORDER BY event_date DESC, hour DESC;

-- Total events per day
SELECT 
    event_date,
    tenant_id,
    count() AS daily_count,
    uniqExact(event_id) AS unique_events,
    count() - uniqExact(event_id) AS duplicates
FROM audit.events
WHERE event_date >= today() - 7
GROUP BY event_date, tenant_id
ORDER BY event_date DESC;

-- Detect potential duplicates
SELECT 
    event_id,
    count() AS occurrence_count
FROM audit.events
WHERE event_date >= today() - 1
GROUP BY event_id
HAVING occurrence_count > 1
LIMIT 100;
