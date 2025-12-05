# Epic 2: Ingestion Pipeline

> **"Data is the new oil, but only if you can capture it."**

---

## 1. Epic Overview

| Field | Value |
|-------|-------|
| **Epic ID** | E2 |
| **Epic Name** | Ingestion Pipeline |
| **Priority** | P0 - Critical Path |
| **Timeline** | Weeks 3-4 |
| **Owner** | Backend Team |
| **Dependencies** | E1 (Infrastructure) |

## 2. Objective

Implementar o pipeline de ingestão de eventos, incluindo API Gateway (APISIX), processamento (Vector), e produção para Redpanda, garantindo alta performance e confiabilidade.

## 3. Success Criteria

- [ ] API Gateway (APISIX) configurado e funcionando
- [ ] Endpoints `/v1/events` e `/v1/events/batch` operacionais
- [ ] Autenticação via API Key funcionando
- [ ] Rate limiting por tenant configurado
- [ ] Vector processando e transformando eventos
- [ ] Eventos sendo produzidos no Redpanda
- [ ] Latência p99 < 200ms para ingestão
- [ ] Zero data loss comprovado

## 4. User Stories

### E2.S1 - APISIX Gateway Setup

| Field | Value |
|-------|-------|
| **Story ID** | E2.S1 |
| **Title** | Configurar Apache APISIX |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Desenvolvedor de Produto**, quero um API Gateway configurado, para que as requisições sejam autenticadas, validadas e roteadas corretamente.

**Acceptance Criteria**:
- [ ] APISIX deployado com 3 réplicas
- [ ] etcd cluster para configuração
- [ ] Rotas configuradas para `/v1/events*`
- [ ] Health check endpoint `/health`
- [ ] APISIX Dashboard acessível
- [ ] Logs estruturados (JSON)
- [ ] Métricas Prometheus expostas

**Technical Notes**:
```yaml
routes:
  - uri: /v1/events
    methods: ["POST"]
    upstream:
      type: roundrobin
      nodes:
        - host: vector
          port: 8080
  - uri: /v1/events/batch
    methods: ["POST"]
    upstream:
      type: roundrobin
      nodes:
        - host: vector
          port: 8080
```

---

### E2.S2 - API Key Authentication

| Field | Value |
|-------|-------|
| **Story ID** | E2.S2 |
| **Title** | Implementar Autenticação por API Key |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Marina (Platform Engineer)**, quero autenticar minhas requisições com uma API Key, para que apenas sistemas autorizados possam enviar eventos.

**Acceptance Criteria**:
- [ ] Plugin key-auth configurado no APISIX
- [ ] API Keys armazenadas no PostgreSQL
- [ ] Header `X-API-Key` validado
- [ ] Tenant ID extraído da API Key
- [ ] Resposta 401 para keys inválidas
- [ ] Resposta 403 para keys revogadas
- [ ] Rate limit por API Key

**Technical Notes**:
```sql
-- Schema para API Keys
CREATE TABLE api_keys (
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
```

---

### E2.S3 - Rate Limiting

| Field | Value |
|-------|-------|
| **Story ID** | E2.S3 |
| **Title** | Implementar Rate Limiting |
| **Priority** | P0 |
| **Points** | 3 |

**User Story**:
Como **Administrador**, quero limitar requisições por API Key, para proteger a plataforma de uso abusivo.

**Acceptance Criteria**:
- [ ] Plugin limit-count configurado
- [ ] Limites armazenados no Redis
- [ ] Headers `X-RateLimit-*` nas respostas
- [ ] Resposta 429 quando limite excedido
- [ ] Limites customizáveis por tenant

**Technical Notes**:
```yaml
plugins:
  limit-count:
    count: 10000
    time_window: 60
    key_type: var
    key: $http_x_api_key
    policy: redis
    redis_host: redis
```

---

### E2.S4 - Vector HTTP Source

| Field | Value |
|-------|-------|
| **Story ID** | E2.S4 |
| **Title** | Configurar Vector HTTP Ingestion |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Engenheiro de Dados**, quero o Vector recebendo eventos via HTTP, para processá-los antes de enviar ao Redpanda.

**Acceptance Criteria**:
- [ ] Vector deployado com 3 réplicas
- [ ] HTTP source na porta 8080
- [ ] Buffer em disco (1GB) configurado
- [ ] Health check endpoint
- [ ] Métricas Prometheus expostas

**Technical Notes**:
```toml
[sources.http_ingest]
type = "http_server"
address = "0.0.0.0:8080"
encoding = "json"
```

---

### E2.S5 - Event Schema Validation

| Field | Value |
|-------|-------|
| **Story ID** | E2.S5 |
| **Title** | Validar Schema dos Eventos |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Marina (Platform Engineer)**, quero receber erros claros quando meu payload estiver incorreto, para corrigir a integração rapidamente.

**Acceptance Criteria**:
- [ ] Campos obrigatórios validados (actor, action, resource)
- [ ] Tipos de dados validados
- [ ] Mensagens de erro descritivas
- [ ] Eventos inválidos rejeitados com 400
- [ ] Eventos válidos aceitos com 202

**Technical Notes**:
```toml
[transforms.validate]
type = "remap"
source = '''
assert!(exists(.actor.id), "actor.id is required")
assert!(exists(.action.name), "action.name is required")
assert!(exists(.resource.type), "resource.type is required")
assert!(exists(.resource.id), "resource.id is required")
'''
```

---

### E2.S6 - Event Enrichment

| Field | Value |
|-------|-------|
| **Story ID** | E2.S6 |
| **Title** | Enriquecer Eventos |
| **Priority** | P1 |
| **Points** | 3 |

**User Story**:
Como **Engenheiro de Dados**, quero que eventos sejam enriquecidos automaticamente, para ter metadados consistentes.

**Acceptance Criteria**:
- [ ] `event_id` (UUID v7) gerado automaticamente
- [ ] `received_at` timestamp adicionado
- [ ] `event_date` calculado para partitioning
- [ ] `processing.vector_node` adicionado
- [ ] Action name normalizado para lowercase

**Technical Notes**:
```toml
[transforms.enrich]
type = "remap"
source = '''
.event_id = uuid_v7()
.received_at = now()
.event_date = format_timestamp!(.timestamp, "%Y-%m-%d")
.action.name = downcase!(.action.name)
'''
```

---

### E2.S7 - Redpanda Producer

| Field | Value |
|-------|-------|
| **Story ID** | E2.S7 |
| **Title** | Produzir Eventos para Redpanda |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Engenheiro de Dados**, quero que eventos sejam produzidos para Redpanda, para garantir durabilidade antes do processamento.

**Acceptance Criteria**:
- [ ] Sink Kafka configurado para Redpanda
- [ ] Topic `audit.events.v1`
- [ ] Partitioning por `tenant_id`
- [ ] Compression LZ4 habilitada
- [ ] Batching otimizado (1MB ou 1s)
- [ ] Acks = all para durabilidade
- [ ] DLQ para eventos com falha

**Technical Notes**:
```toml
[sinks.redpanda]
type = "kafka"
bootstrap_servers = "redpanda:9092"
topic = "audit.events.v1"
key_field = "tenant_id"
compression = "lz4"
encoding.codec = "json"

[sinks.redpanda.batch]
max_bytes = 1048576
timeout_secs = 1
```

---

### E2.S8 - Single Event Endpoint

| Field | Value |
|-------|-------|
| **Story ID** | E2.S8 |
| **Title** | Endpoint POST /v1/events |
| **Priority** | P0 |
| **Points** | 3 |

**User Story**:
Como **Marina (Platform Engineer)**, quero enviar um evento único via API, para auditar ações individuais do meu produto.

**Acceptance Criteria**:
- [ ] `POST /v1/events` aceita JSON único
- [ ] Resposta 202 Accepted com `event_id`
- [ ] Resposta 400 para payload inválido
- [ ] Resposta 401 para API Key inválida
- [ ] Resposta 429 para rate limit excedido
- [ ] Latência p99 < 100ms

**API Contract**:
```http
POST /v1/events
Content-Type: application/json
X-API-Key: <api-key>

{
  "actor": { "id": "user-123", "type": "user", "email": "user@example.com" },
  "action": { "name": "user.created" },
  "resource": { "type": "user", "id": "user-456" },
  "timestamp": "2024-12-05T10:00:00Z",
  "result": { "success": true }
}

Response: 202 Accepted
{
  "event_id": "0192d4e5-8a7c-7def-9012-3456789abcde",
  "received_at": "2024-12-05T10:00:00.123Z"
}
```

---

### E2.S9 - Batch Event Endpoint

| Field | Value |
|-------|-------|
| **Story ID** | E2.S9 |
| **Title** | Endpoint POST /v1/events/batch |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Marina (Platform Engineer)**, quero enviar múltiplos eventos em uma única requisição, para otimizar a performance da minha aplicação.

**Acceptance Criteria**:
- [ ] `POST /v1/events/batch` aceita array de eventos
- [ ] Máximo 1000 eventos por batch
- [ ] Resposta 202 com lista de `event_ids`
- [ ] Partial success: eventos válidos aceitos, inválidos rejeitados
- [ ] Resposta inclui count de success/failed
- [ ] Latência p99 < 500ms para batch de 100 eventos

**API Contract**:
```http
POST /v1/events/batch
Content-Type: application/json
X-API-Key: <api-key>

{
  "events": [
    { "actor": {...}, "action": {...}, "resource": {...} },
    { "actor": {...}, "action": {...}, "resource": {...} }
  ]
}

Response: 202 Accepted
{
  "accepted": 2,
  "rejected": 0,
  "events": [
    { "event_id": "uuid-1", "status": "accepted" },
    { "event_id": "uuid-2", "status": "accepted" }
  ]
}
```

---

## 5. Dependencies

| Dependency | Type | Description |
|------------|------|-------------|
| E1.S1 | Internal | Kubernetes cluster |
| E1.S2 | Internal | Redpanda cluster |
| E1.S5 | Internal | PostgreSQL for API keys |
| E1.S6 | Internal | Redis for rate limiting |

## 6. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Latência alta | High | Otimizar Vector config, tune buffers |
| Perda de dados | Critical | Disk buffer no Vector, acks=all no Kafka |
| Rate limiting incorreto | Medium | Testes de carga, tuning |

## 7. Definition of Done

- [ ] Endpoints funcionando e documentados
- [ ] Testes de integração passando
- [ ] Load test: 5000 req/s sustentado
- [ ] Latência p99 < 200ms
- [ ] Zero data loss em testes de falha
- [ ] Documentação da API (OpenAPI)
- [ ] SDK de exemplo funcionando

---

**Status**: Draft  
**Created**: 2024-12-05  
**Last Updated**: 2024-12-05
