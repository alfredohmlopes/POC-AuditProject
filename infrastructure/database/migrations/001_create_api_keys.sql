-- 001_create_api_keys.sql
CREATE TABLE IF NOT EXISTS api_keys (
    id UUID PRIMARY KEY,
    key_hash VARCHAR(64) NOT NULL, -- SHA-256
    tenant_id UUID NOT NULL,
    name VARCHAR(255),
    scopes TEXT[], -- ['events:write', 'events:read']
    rate_limit INT DEFAULT 10000, -- per minute
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    last_used_at TIMESTAMPTZ
);
