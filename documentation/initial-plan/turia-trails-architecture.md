# Turia Trails: Architecture Decision Document

> **"Make it work, make it right, make it fast."**  
> — Kent Beck

---

## 1. Executive Summary

### 1.1 Volume Real

| Métrica | Valor | Cálculo |
|---------|-------|---------|
| **Eventos/dia** | 100M+ | Baseline conhecido |
| **Eventos/hora** | ~4.2M | 100M / 24 |
| **Eventos/segundo** | **~1.200** | 100M / 86.400 |
| **Eventos/segundo (pico 3x)** | **~3.600** | Picos de utilização |
| **Tamanho médio evento** | ~2 KB | Estimativa conservadora |
| **Throughput** | ~2.4 MB/s (7.2 MB/s pico) | 1.200 × 2 KB |
| **Storage/dia** | ~200 GB | 100M × 2 KB |
| **Storage/90 dias** | **~18 TB** | 200 GB × 90 |

### 1.2 Conclusão

Com **~1.200 eventos/segundo** (picos de 3.600+), a arquitetura precisa de:

- ✅ **Buffer distribuído** (Redpanda) - Redis Streams não escala
- ✅ **Storage OLAP** (ClickHouse) - PostgreSQL não aguenta insert rate
- ✅ **Ingestão otimizada** (Vector) - Alta performance, baixo footprint
- ✅ **Busca especializada** (OpenSearch) - Full-text em 18 TB

**Sua proposta original está CORRETA para este volume.**

---

## 2. Arquitetura Validada

### 2.1 Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    TURIA TRAILS - HIGH VOLUME ARCHITECTURE              │
└─────────────────────────────────────────────────────────────────────────┘

          ┌─────────────────────────────────────────────────────────┐
          │                     PRODUCERS                            │
          │                                                          │
          │   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐ │
          │   │ID Magalu│   │  RBAC   │   │  Prod A │   │  Prod N │ │
          │   └────┬────┘   └────┬────┘   └────┬────┘   └────┬────┘ │
          │        │             │             │             │       │
          └────────┼─────────────┼─────────────┼─────────────┼───────┘
                   │             │             │             │
                   └─────────────┴──────┬──────┴─────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         INGESTION LAYER                                  │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                    Load Balancer (L4)                            │   │
│   │              (HAProxy / AWS NLB / Nginx Stream)                  │   │
│   └──────────────────────────────┬──────────────────────────────────┘   │
│                                  │                                       │
│   ┌──────────────────────────────┴──────────────────────────────────┐   │
│   │                     API Gateway Layer                            │   │
│   │                                                                  │   │
│   │   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐           │   │
│   │   │   APISIX    │   │   APISIX    │   │   APISIX    │           │   │
│   │   │  (Node 1)   │   │  (Node 2)   │   │  (Node N)   │           │   │
│   │   │             │   │             │   │             │           │   │
│   │   │ • Auth      │   │ • Auth      │   │ • Auth      │           │   │
│   │   │ • Rate Limit│   │ • Rate Limit│   │ • Rate Limit│           │   │
│   │   │ • Validate  │   │ • Validate  │   │ • Validate  │           │   │
│   │   └──────┬──────┘   └──────┬──────┘   └──────┬──────┘           │   │
│   │          │                 │                 │                  │   │
│   └──────────┴─────────────────┴─────────────────┴──────────────────┘   │
│                                  │                                       │
│   ┌──────────────────────────────┴──────────────────────────────────┐   │
│   │                     Vector Aggregator                            │   │
│   │                                                                  │   │
│   │   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐           │   │
│   │   │   Vector    │   │   Vector    │   │   Vector    │           │   │
│   │   │  (Node 1)   │   │  (Node 2)   │   │  (Node N)   │           │   │
│   │   │             │   │             │   │             │           │   │
│   │   │ • Buffer    │   │ • Buffer    │   │ • Buffer    │           │   │
│   │   │ • Transform │   │ • Transform │   │ • Transform │           │   │
│   │   │ • Batch     │   │ • Batch     │   │ • Batch     │           │   │
│   │   └──────┬──────┘   └──────┬──────┘   └──────┬──────┘           │   │
│   │          │                 │                 │                  │   │
│   └──────────┴─────────────────┴─────────────────┴──────────────────┘   │
│                                  │                                       │
└──────────────────────────────────┼───────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         STREAMING LAYER                                  │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                     Redpanda Cluster                             │   │
│   │                                                                  │   │
│   │   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐           │   │
│   │   │  Broker 1   │   │  Broker 2   │   │  Broker 3   │           │   │
│   │   │             │   │             │   │             │           │   │
│   │   │ Partition 0 │   │ Partition 1 │   │ Partition 2 │           │   │
│   │   │ Partition 3 │   │ Partition 4 │   │ Partition 5 │           │   │
│   │   └─────────────┘   └─────────────┘   └─────────────┘           │   │
│   │                                                                  │   │
│   │   Topics:                                                        │   │
│   │   • audit.events.v1 (partitioned by tenant_id)                  │   │
│   │   • audit.events.dlq (dead letter queue)                        │   │
│   │                                                                  │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└──────────────────────────────────┬───────────────────────────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
                    ▼                             ▼
┌─────────────────────────────────┐ ┌─────────────────────────────────┐
│        ANALYTICS STORE          │ │         SEARCH STORE            │
│                                 │ │                                 │
│   ┌─────────────────────────┐   │ │   ┌─────────────────────────┐   │
│   │      ClickHouse         │   │ │   │      OpenSearch         │   │
│   │       Cluster           │   │ │   │       Cluster           │   │
│   │                         │   │ │   │                         │   │
│   │   ┌───────┐ ┌───────┐   │   │ │   │   ┌───────┐ ┌───────┐   │   │
│   │   │Shard 1│ │Shard 2│   │   │ │   │   │Data 1 │ │Data 2 │   │   │
│   │   └───────┘ └───────┘   │   │ │   │   └───────┘ └───────┘   │   │
│   │   ┌───────┐ ┌───────┐   │   │ │   │   ┌───────┐             │   │
│   │   │Shard 3│ │Shard 4│   │   │ │   │   │Data 3 │             │   │
│   │   └───────┘ └───────┘   │   │ │   │   └───────┘             │   │
│   │                         │   │ │   │                         │   │
│   │  • Primary analytics    │   │ │   │  • Full-text search     │   │
│   │  • Aggregations         │   │ │   │  • Complex queries      │   │
│   │  • Dashboards           │   │ │   │  • Faceted navigation   │   │
│   │  • Long-term storage    │   │ │   │  • Hot tier only        │   │
│   └─────────────────────────┘   │ │   └─────────────────────────┘   │
│                                 │ │                                 │
└─────────────────────────────────┘ └─────────────────────────────────┘
                    │                             │
                    └──────────────┬──────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         COLD STORAGE                                     │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                  Magalu Object Storage (S3)                      │   │
│   │                                                                  │   │
│   │   • Parquet format (columnar, compressed)                       │   │
│   │   • Partitioned by date/tenant                                  │   │
│   │   • Object Lock (WORM) for compliance                           │   │
│   │   • Lifecycle: 90 days hot → cold                               │   │
│   │   • Retention: 1-7 years based on policy                        │   │
│   │                                                                  │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Diagrama de Sequência

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         REQUEST FLOW                                     │
└─────────────────────────────────────────────────────────────────────────┘

  Client          APISIX           Vector         Redpanda        Sinks
    │               │                │               │              │
    │  POST /v1/events (batch)       │               │              │
    │──────────────▸│               │               │              │
    │               │               │               │              │
    │               │ Validate API Key              │              │
    │               │ Check Rate Limit              │              │
    │               │ Schema Validation             │              │
    │               │               │               │              │
    │               │──────────────▸│               │              │
    │               │  Forward      │               │              │
    │               │               │               │              │
    │               │               │ Transform (VRL)              │
    │               │               │ PII Masking   │              │
    │               │               │ Enrich        │              │
    │               │               │ Buffer (mem)  │              │
    │               │               │               │              │
    │               │◀──────────────│               │              │
    │◀──────────────│  202 Accepted │               │              │
    │               │               │               │              │
    │               │               │               │              │
    │               │               │──────────────▸│              │
    │               │               │ Produce Batch │              │
    │               │               │◀──────────────│              │
    │               │               │    Ack        │              │
    │               │               │               │              │
    │               │               │               │              │
    │               │               │               │──────────────▸
    │               │               │               │  Consume     │
    │               │               │               │              │
    │               │               │               │  ┌───────────┤
    │               │               │               │  │ClickHouse │
    │               │               │               │  │ Bulk Insert
    │               │               │               │  ├───────────┤
    │               │               │               │  │OpenSearch │
    │               │               │               │  │ Bulk Index│
    │               │               │               │  └───────────┘
    │               │               │               │              │
```

---

## 3. Stack Tecnológico

### 3.1 Decisões de Tecnologia

| Componente | Tecnologia | Justificativa |
|------------|------------|---------------|
| **Load Balancer** | HAProxy / NLB | L4, alta performance, health checks |
| **API Gateway** | Apache APISIX | OSS, alta performance (Nginx + Lua), plugins ricos |
| **Transform/Buffer** | Vector | Rust, ~10x mais eficiente que Logstash, VRL transforms |
| **Message Queue** | Redpanda | Kafka API, single binary, C++, sem ZooKeeper |
| **Analytics DB** | ClickHouse | OLAP columnar, 100x+ mais rápido que PostgreSQL para analytics |
| **Search Engine** | OpenSearch | OSS Elasticsearch, full-text, facets, aggregations |
| **Cold Storage** | S3 / MGC Object | Parquet, baixo custo, WORM compliance |
| **Metadata DB** | PostgreSQL | API keys, configs, alert rules (baixo volume) |
| **Cache** | Redis | Rate limiting, session, pequenos lookups |
| **Orchestration** | Kubernetes | Stateless scaling, operators |

### 3.2 Por que APISIX e não Kong?

| Aspecto | Kong OSS | Apache APISIX |
|---------|----------|---------------|
| Performance | ~10K req/s | ~30K req/s |
| Arquitetura | Lua + PostgreSQL/Cassandra | Lua + etcd (stateless) |
| Latência | ~2ms overhead | ~0.5ms overhead |
| Plugins | Rico | Muito rico + custom fácil |
| Dashboard | Kong Manager (paid) | APISIX Dashboard (OSS) |
| License | Apache 2.0 | Apache 2.0 |

**Recomendação**: APISIX para alta performance.

### 3.3 Por que ClickHouse + OpenSearch (e não só um)?

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    DUAL-STORE STRATEGY                                   │
└─────────────────────────────────────────────────────────────────────────┘

                      ┌─────────────────────────────────┐
                      │          USE CASES              │
                      └─────────────────────────────────┘
                                     │
              ┌──────────────────────┴──────────────────────┐
              │                                             │
              ▼                                             ▼
    ┌───────────────────────┐                 ┌───────────────────────┐
    │      CLICKHOUSE       │                 │      OPENSEARCH       │
    │   (Primary Store)     │                 │   (Search Layer)      │
    ├───────────────────────┤                 ├───────────────────────┤
    │                       │                 │                       │
    │ ✓ ALL events (source  │                 │ ✓ Hot tier only       │
    │   of truth)           │                 │   (7-30 days)         │
    │                       │                 │                       │
    │ ✓ Aggregations        │                 │ ✓ Full-text search    │
    │   "Count by action    │                 │   "password reset"    │
    │    last 30 days"      │                 │                       │
    │                       │                 │ ✓ Fuzzy matching      │
    │ ✓ Time-series queries │                 │   "pasword reset"→hit │
    │   "Events per hour"   │                 │                       │
    │                       │                 │ ✓ Faceted navigation  │
    │ ✓ Long-term storage   │                 │   Filters + counts    │
    │   (90 days+)          │                 │                       │
    │                       │                 │ ✓ Highlighting        │
    │ ✓ Cold tier offload   │                 │   Show matches        │
    │   → S3 Parquet        │                 │                       │
    │                       │                 │                       │
    │ Compression: 10-20x   │                 │ Compression: 3-5x     │
    │ Storage: ~200 GB/day  │                 │ Storage: ~600 GB/7days│
    │ (compressed)          │                 │                       │
    └───────────────────────┘                 └───────────────────────┘
```

**Por que não só ClickHouse?**
- ClickHouse não faz full-text search bem
- Fuzzy matching é lento
- Facets complexos são limitados

**Por que não só OpenSearch?**
- Storage muito caro para 90 dias
- Aggregations em volume alto são lentas
- Não é source-of-truth ideal

**Solução**: ClickHouse como store principal, OpenSearch como índice de busca (hot tier).

---

## 4. Sizing & Capacity Planning

### 4.1 Cálculos de Capacidade

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      CAPACITY CALCULATIONS                               │
└─────────────────────────────────────────────────────────────────────────┘

Volume Base:
├── 100M eventos/dia
├── ~1.200 eventos/segundo (avg)
├── ~3.600 eventos/segundo (peak 3x)
└── ~2 KB/evento

Storage Raw:
├── 100M × 2 KB = 200 GB/dia (raw)
├── 90 dias = 18 TB (raw)
└── 1 ano = 73 TB (raw)

Storage com Compressão:
├── ClickHouse (10-20x): 10-20 GB/dia → 900 GB - 1.8 TB / 90 dias
├── OpenSearch (3-5x): 40-66 GB/dia → 280-500 GB / 7 dias
└── Parquet Cold (15x): ~13 GB/dia → ~4.7 TB/ano

Throughput:
├── Ingestion: 1.200 ev/s × 2 KB = 2.4 MB/s (avg)
├── Peak: 3.600 ev/s × 2 KB = 7.2 MB/s
└── Network: ~10 Gbps sufficient
```

### 4.2 Cluster Sizing

#### Redpanda Cluster

| Spec | Value | Justificativa |
|------|-------|---------------|
| **Nodes** | 3 | Mínimo para HA (replication factor 3) |
| **vCPUs/node** | 8 | Handle peak throughput |
| **RAM/node** | 32 GB | Page cache, buffers |
| **Disk/node** | 1 TB NVMe | 3 dias de retenção hot |
| **Partitions** | 12-24 | 4-8 per broker, paralelismo |

```
Throughput Target: 3.600 msg/s peak × 2 KB = 7.2 MB/s
Redpanda Capacity: 3 nodes × 100 MB/s = 300 MB/s (40x headroom)
```

#### ClickHouse Cluster

| Spec | Value | Justificativa |
|------|-------|---------------|
| **Nodes** | 3 (1 shard × 3 replicas) ou 6 (2 shards × 3 replicas) | HA + query parallelism |
| **vCPUs/node** | 16 | Aggregations pesadas |
| **RAM/node** | 64 GB | Query processing |
| **Disk/node** | 2 TB NVMe | 90 dias compressed |

```
Insert Rate: 1.200 ev/s = 72K ev/min
ClickHouse Capacity: Easily handles 500K+ inserts/second
```

#### OpenSearch Cluster

| Spec | Value | Justificativa |
|------|-------|---------------|
| **Data Nodes** | 3 | Distribuição de shards |
| **vCPUs/node** | 8 | Indexing + queries |
| **RAM/node** | 32 GB | JVM heap 16 GB |
| **Disk/node** | 500 GB NVMe | 7 dias hot |
| **Master Nodes** | 3 (small) | Cluster coordination |

```
Index Rate: 1.200 docs/s
OpenSearch Capacity: 3 nodes easily handle 10K+ docs/s
```

### 4.3 Infraestrutura Total (MVP)

| Componente | Nodes | Spec | Storage | Custo Est./mês |
|------------|-------|------|---------|----------------|
| **APISIX** | 3 | 4 vCPU, 8 GB | - | $150 |
| **Vector** | 3 | 4 vCPU, 8 GB | - | $150 |
| **Redpanda** | 3 | 8 vCPU, 32 GB | 1 TB NVMe | $600 |
| **ClickHouse** | 3 | 16 vCPU, 64 GB | 2 TB NVMe | $1,200 |
| **OpenSearch** | 3+3 | 8 vCPU, 32 GB | 500 GB NVMe | $800 |
| **PostgreSQL** | 1 | 2 vCPU, 8 GB | 100 GB | $100 |
| **Redis** | 1 | 4 GB | - | $50 |
| **Object Storage** | - | - | 5 TB | $100 |
| **Network/LB** | - | - | - | $100 |
| **Total** | | | | **~$3,250/mês** |

---

## 5. Data Model

### 5.1 Event Schema (Unified)

```json
{
  "event_id": "0192d4e5-8a7c-7def-9012-3456789abcde",
  "event_version": "1.0",
  "timestamp": "2024-12-05T14:30:45.123Z",
  "received_at": "2024-12-05T14:30:45.234Z",
  
  "tenant": {
    "id": "tenant-uuid",
    "name": "Empresa XYZ"
  },
  
  "actor": {
    "id": "user-uuid",
    "type": "user",
    "email": "admin@empresa.com",
    "name": "João Silva",
    "ip_address": "200.10.20.30",
    "user_agent": "Mozilla/5.0...",
    "session_id": "session-uuid"
  },
  
  "action": {
    "name": "user.role_assigned",
    "category": "authorization",
    "type": "write"
  },
  
  "resource": {
    "type": "user",
    "id": "target-user-uuid",
    "name": "maria@empresa.com"
  },
  
  "result": {
    "success": true,
    "error_code": null,
    "error_message": null
  },
  
  "changes": {
    "before": { "roles": ["viewer"] },
    "after": { "roles": ["viewer", "admin"] }
  },
  
  "context": {
    "source_service": "rbac-api",
    "source_version": "2.1.0",
    "request_id": "req-uuid",
    "trace_id": "trace-uuid"
  },
  
  "metadata": {
    "ticket_id": "JIRA-1234",
    "approved_by": "manager-uuid"
  }
}
```

### 5.2 ClickHouse Table Schema

```sql
-- Main events table with MergeTree engine
CREATE TABLE audit_events
(
    -- Identifiers
    event_id UUID,
    event_version String DEFAULT '1.0',
    
    -- Timestamps
    timestamp DateTime64(3),
    received_at DateTime64(3),
    
    -- Tenant (for filtering)
    tenant_id UUID,
    tenant_name LowCardinality(String),
    
    -- Actor
    actor_id UUID,
    actor_type LowCardinality(String),
    actor_email String,
    actor_name String,
    actor_ip IPv4,
    actor_user_agent String,
    actor_session_id UUID,
    
    -- Action
    action_name LowCardinality(String),
    action_category LowCardinality(String),
    action_type LowCardinality(String),
    
    -- Resource
    resource_type LowCardinality(String),
    resource_id UUID,
    resource_name String,
    
    -- Result
    success Bool,
    error_code LowCardinality(String),
    error_message String,
    
    -- Changes (JSON)
    changes_before String,  -- JSON string
    changes_after String,   -- JSON string
    
    -- Context
    source_service LowCardinality(String),
    source_version LowCardinality(String),
    request_id UUID,
    trace_id String,
    
    -- Metadata (flexible)
    metadata String,  -- JSON string
    
    -- Partition key
    event_date Date DEFAULT toDate(timestamp)
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(event_date)
ORDER BY (tenant_id, action_name, timestamp)
TTL event_date + INTERVAL 90 DAY
SETTINGS index_granularity = 8192;

-- Materialized view for aggregations
CREATE MATERIALIZED VIEW audit_events_hourly
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(hour)
ORDER BY (tenant_id, action_name, hour)
AS SELECT
    tenant_id,
    action_name,
    action_category,
    success,
    toStartOfHour(timestamp) AS hour,
    count() AS event_count
FROM audit_events
GROUP BY tenant_id, action_name, action_category, success, hour;
```

### 5.3 OpenSearch Index Mapping

```json
{
  "mappings": {
    "properties": {
      "event_id": { "type": "keyword" },
      "timestamp": { "type": "date" },
      
      "tenant_id": { "type": "keyword" },
      
      "actor": {
        "properties": {
          "id": { "type": "keyword" },
          "type": { "type": "keyword" },
          "email": { 
            "type": "text",
            "fields": { "keyword": { "type": "keyword" } }
          },
          "name": { "type": "text" },
          "ip_address": { "type": "ip" }
        }
      },
      
      "action": {
        "properties": {
          "name": { "type": "keyword" },
          "category": { "type": "keyword" }
        }
      },
      
      "resource": {
        "properties": {
          "type": { "type": "keyword" },
          "id": { "type": "keyword" },
          "name": { "type": "text" }
        }
      },
      
      "result": {
        "properties": {
          "success": { "type": "boolean" },
          "error_message": { "type": "text" }
        }
      },
      
      "changes": {
        "type": "flattened"
      },
      
      "metadata": {
        "type": "flattened"
      },
      
      "_all_text": {
        "type": "text",
        "analyzer": "standard"
      }
    }
  },
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 1,
    "refresh_interval": "5s"
  }
}
```

---

## 6. Vector Configuration

### 6.1 Vector Pipeline

```toml
# vector.toml

# ========== SOURCES ==========

[sources.http_ingest]
type = "http_server"
address = "0.0.0.0:8080"
encoding = "json"
headers = ["X-API-Key", "X-Tenant-ID"]

# ========== TRANSFORMS ==========

[transforms.parse_and_validate]
type = "remap"
inputs = ["http_ingest"]
source = '''
# Validate required fields
assert!(exists(.actor.id), "actor.id is required")
assert!(exists(.action.name), "action.name is required")
assert!(exists(.resource.type), "resource.type is required")

# Add metadata
.received_at = now()
.event_id = uuid_v7()

# Normalize action name
.action.name = downcase!(.action.name)

# Extract tenant from header or payload
.tenant_id = get_env_var("X_TENANT_ID") ?? .tenant.id ?? "unknown"
'''

[transforms.pii_masking]
type = "remap"
inputs = ["parse_and_validate"]
source = '''
# Mask email in logs (keep in actor.email)
if exists(.actor.email) {
  .actor.email_masked = replace(.actor.email, r'(?P<name>[^@]+)@', "***@")
}

# Mask IP last octet for privacy
if exists(.actor.ip_address) {
  .actor.ip_masked = replace(.actor.ip_address, r'\.\d+$', ".xxx")
}
'''

[transforms.enrich]
type = "remap"
inputs = ["pii_masking"]
source = '''
# Add processing metadata
.processing = {
  "vector_node": get_hostname!(),
  "processed_at": now()
}

# Compute event_date for partitioning
.event_date = format_timestamp!(.timestamp, "%Y-%m-%d")
'''

# ========== SINKS ==========

[sinks.redpanda]
type = "kafka"
inputs = ["enrich"]
bootstrap_servers = "redpanda-0:9092,redpanda-1:9092,redpanda-2:9092"
topic = "audit.events.v1"
encoding.codec = "json"
compression = "lz4"

# Batching for performance
batch.max_bytes = 1048576  # 1 MB
batch.timeout_secs = 1

# Key by tenant for partition locality
key_field = "tenant_id"

[sinks.redpanda.buffer]
type = "disk"
max_size = 1073741824  # 1 GB disk buffer
when_full = "block"

# Metrics for monitoring
[sinks.prometheus]
type = "prometheus_exporter"
inputs = ["enrich"]
address = "0.0.0.0:9598"
```

### 6.2 Vector Consumer (para ClickHouse/OpenSearch)

```toml
# vector-consumer.toml

[sources.redpanda]
type = "kafka"
bootstrap_servers = "redpanda-0:9092,redpanda-1:9092,redpanda-2:9092"
group_id = "vector-consumers"
topics = ["audit.events.v1"]
auto_offset_reset = "earliest"

[sinks.clickhouse]
type = "clickhouse"
inputs = ["redpanda"]
endpoint = "http://clickhouse:8123"
database = "audit"
table = "audit_events"
compression = "lz4"

batch.max_events = 10000
batch.timeout_secs = 5

[sinks.opensearch]
type = "elasticsearch"
inputs = ["redpanda"]
endpoints = ["http://opensearch:9200"]
bulk.index = "audit-events-%Y-%m-%d"
compression = "gzip"

batch.max_events = 5000
batch.timeout_secs = 5
```

---

## 7. API Design

### 7.1 Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/v1/events` | Ingest single event |
| `POST` | `/v1/events/batch` | Ingest batch (max 1000) |
| `GET` | `/v1/events` | Search/list events |
| `GET` | `/v1/events/{id}` | Get single event |
| `GET` | `/v1/events/aggregations` | Get aggregated metrics |
| `GET` | `/v1/health` | Health check |

### 7.2 Authentication

```yaml
# APISIX route configuration
routes:
  - uri: /v1/events*
    methods: ["POST", "GET"]
    plugins:
      key-auth:
        header: "X-API-Key"
      limit-count:
        count: 10000
        time_window: 60
        key_type: "var"
        key: "$http_x_api_key"
        policy: "redis"
        redis_host: "redis"
        redis_port: 6379
```

### 7.3 Rate Limiting Tiers

| Tier | Requests/min | Events/batch | Retention |
|------|--------------|--------------|-----------|
| **Free** | 100 | 100 | 7 days |
| **Standard** | 10,000 | 1,000 | 90 days |
| **Enterprise** | Unlimited | 10,000 | Custom |

---

## 8. Deployment Architecture

### 8.1 Kubernetes Deployment

```yaml
# High-level resource allocation
apiVersion: v1
kind: Namespace
metadata:
  name: turia-trails
---
# APISIX (3 replicas)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apisix
  namespace: turia-trails
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: apisix
        image: apache/apisix:3.7.0-debian
        resources:
          requests:
            cpu: "2"
            memory: "4Gi"
          limits:
            cpu: "4"
            memory: "8Gi"
---
# Vector Aggregator (3 replicas)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vector-aggregator
  namespace: turia-trails
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: vector
        image: timberio/vector:0.34.1-debian
        resources:
          requests:
            cpu: "2"
            memory: "4Gi"
          limits:
            cpu: "4"
            memory: "8Gi"
        volumeMounts:
        - name: buffer
          mountPath: /var/lib/vector
      volumes:
      - name: buffer
        persistentVolumeClaim:
          claimName: vector-buffer
```

### 8.2 Multi-Region (Future)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    MULTI-REGION ARCHITECTURE (FUTURE)                    │
└─────────────────────────────────────────────────────────────────────────┘

         Region: São Paulo                    Region: Virginia
              │                                     │
              ▼                                     ▼
      ┌───────────────┐                    ┌───────────────┐
      │   Users BR    │                    │   Users US    │
      └───────┬───────┘                    └───────┬───────┘
              │                                     │
              ▼                                     ▼
      ┌───────────────┐                    ┌───────────────┐
      │   Ingestion   │                    │   Ingestion   │
      │   (Local)     │                    │   (Local)     │
      └───────┬───────┘                    └───────┬───────┘
              │                                     │
              └──────────────┬──────────────────────┘
                             │
                             ▼
                    ┌───────────────────┐
                    │   Redpanda        │
                    │   (Cross-region   │
                    │    replication)   │
                    └───────────────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
      ┌───────────────┐             ┌───────────────┐
      │ ClickHouse BR │◀───────────▸│ ClickHouse US │
      │   (Primary)   │  Replication│   (Replica)   │
      └───────────────┘             └───────────────┘
```

---

## 9. Observability

### 9.1 Metrics (Prometheus)

```yaml
# Key metrics to monitor
metrics:
  # Ingestion
  - name: turia_events_received_total
    type: counter
    labels: [tenant_id, action_category]
    
  - name: turia_events_processed_total
    type: counter
    labels: [tenant_id, sink]
    
  - name: turia_ingestion_latency_seconds
    type: histogram
    labels: [tenant_id]
    
  # Redpanda
  - name: redpanda_kafka_consumer_lag
    type: gauge
    labels: [topic, consumer_group]
    
  # ClickHouse
  - name: clickhouse_inserts_per_second
    type: gauge
    
  - name: clickhouse_query_duration_seconds
    type: histogram
```

### 9.2 SLOs

| SLI | SLO | Measurement |
|-----|-----|-------------|
| **Availability (Ingestion)** | 99.95% | HTTP 2xx responses |
| **Latency (Ingestion p99)** | < 200ms | Time to 202 Accepted |
| **Latency (Search p99)** | < 2s | Query response time |
| **Durability** | 99.9999% | No data loss |
| **Freshness** | < 30s | Time to searchable |

### 9.3 Alerting Rules

```yaml
# Critical Alerts
alerts:
  - name: HighConsumerLag
    condition: redpanda_consumer_lag > 1000000
    severity: critical
    
  - name: VectorBufferFull
    condition: vector_buffer_usage_percent > 90
    severity: critical
    
  - name: ClickHouseInsertFailures
    condition: rate(clickhouse_insert_errors[5m]) > 0
    severity: warning
    
  - name: HighIngestionLatency
    condition: histogram_quantile(0.99, turia_ingestion_latency) > 0.5
    severity: warning
```

---

## 10. Security

### 10.1 Network Security

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      NETWORK SEGMENTATION                                │
└─────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────────────────┐
    │                      PUBLIC ZONE                                  │
    │                                                                   │
    │   Internet ──▸ Load Balancer ──▸ APISIX (TLS termination)       │
    │                                                                   │
    └────────────────────────────────┬─────────────────────────────────┘
                                     │ (mTLS)
    ┌────────────────────────────────┴─────────────────────────────────┐
    │                      DMZ                                          │
    │                                                                   │
    │   Vector Aggregators                                             │
    │                                                                   │
    └────────────────────────────────┬─────────────────────────────────┘
                                     │ (mTLS)
    ┌────────────────────────────────┴─────────────────────────────────┐
    │                      PRIVATE ZONE                                 │
    │                                                                   │
    │   Redpanda │ ClickHouse │ OpenSearch │ PostgreSQL │ Redis       │
    │                                                                   │
    │   (No internet access, internal only)                            │
    │                                                                   │
    └──────────────────────────────────────────────────────────────────┘
```

### 10.2 Encryption

| Layer | Method |
|-------|--------|
| **In Transit (External)** | TLS 1.3 |
| **In Transit (Internal)** | mTLS (mutual TLS) |
| **At Rest** | AES-256 (storage encryption) |
| **Secrets** | Vault / K8s Secrets (encrypted) |

### 10.3 Immutability (WORM)

```yaml
# S3 Object Lock configuration
bucket_configuration:
  object_lock:
    enabled: true
    default_retention:
      mode: COMPLIANCE  # Cannot be shortened/deleted
      days: 365
```

---

## 11. Phased Rollout

### 11.1 Phase 1: Core Platform (Weeks 1-8)

| Week | Deliverable |
|------|-------------|
| 1-2 | Infra setup (K8s, Redpanda, ClickHouse) |
| 3-4 | APISIX + Vector pipeline |
| 5-6 | ClickHouse schema + ingestion |
| 7-8 | API endpoints + SDK |

**Exit Criteria:**
- [ ] 100M events/day ingested
- [ ] < 200ms ingestion latency
- [ ] Query API functional

### 11.2 Phase 2: Search & Dashboard (Weeks 9-12)

| Week | Deliverable |
|------|-------------|
| 9-10 | OpenSearch setup + indexing |
| 11-12 | Dashboard MVP |

**Exit Criteria:**
- [ ] Full-text search working
- [ ] Dashboard with search/filter

### 11.3 Phase 3: Alerting & Polish (Weeks 13-16)

| Week | Deliverable |
|------|-------------|
| 13-14 | Alert engine |
| 15-16 | Cold storage + polish |

**Exit Criteria:**
- [ ] 5 alert rules active
- [ ] S3 offload working
- [ ] Production ready

---

## 12. Decision Log

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | APISIX over Kong | Higher performance, OSS dashboard |
| D2 | Vector over Logstash/Fluentd | 10x more efficient, Rust |
| D3 | Redpanda over Kafka | Simpler ops, no ZooKeeper |
| D4 | ClickHouse + OpenSearch | Best of both: analytics + search |
| D5 | ClickHouse over TimescaleDB | Better compression, faster aggregations |
| D6 | OpenSearch over Elasticsearch | OSS, no license issues |

---

## 13. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Redpanda learning curve** | Medium | Use Kafka ecosystem tools, training |
| **ClickHouse ops complexity** | Medium | Start with managed or simple setup |
| **Dual-store sync issues** | Low | Idempotent consumers, reconciliation |
| **Cost overrun** | Medium | Reserved instances, monitoring |

---

**Status**: Revised  
**Versão**: 2.0  
**Última atualização**: 2024-12-05  
**Aprovação necessária**: Infra/SRE, Security
