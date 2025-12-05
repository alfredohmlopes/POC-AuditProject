# Epic 4: Query API

> **"Ask and you shall receive."**

---

## 1. Epic Overview

| Field | Value |
|-------|-------|
| **Epic ID** | E4 |
| **Epic Name** | Query API |
| **Priority** | P0 - Critical Path |
| **Timeline** | Weeks 7-8 |
| **Owner** | Backend Team |
| **Dependencies** | E3 (Storage) |

## 2. Objective

Implementar a API de consulta de eventos, permitindo busca, filtros, paginação e agregações, utilizando ClickHouse para analytics e OpenSearch para full-text search.

## 3. Success Criteria

- [ ] Endpoint GET /v1/events funcionando
- [ ] Busca full-text operacional
- [ ] Filtros por action, actor, resource, date range
- [ ] Paginação cursor-based
- [ ] Latência p95 < 2s para queries simples
- [ ] Export para CSV funcionando

## 4. User Stories

### E4.S1 - Query Service Setup

| Field | Value |
|-------|-------|
| **Story ID** | E4.S1 |
| **Title** | Criar Query Service |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Desenvolvedor Backend**, quero um serviço de query separado, para consultar eventos de forma otimizada.

**Acceptance Criteria**:
- [ ] Serviço deployado (Go ou Node.js)
- [ ] Conexão com ClickHouse (analytics)
- [ ] Conexão com OpenSearch (search)
- [ ] Health check endpoint
- [ ] Métricas Prometheus

---

### E4.S2 - List Events Endpoint

| Field | Value |
|-------|-------|
| **Story ID** | E4.S2 |
| **Title** | Endpoint GET /v1/events |
| **Priority** | P0 |
| **Points** | 8 |

**User Story**:
Como **Ana (Security Analyst)**, quero listar eventos com filtros, para investigar atividades suspeitas.

**Acceptance Criteria**:
- [ ] `GET /v1/events` retorna lista de eventos
- [ ] Filtro por `action` (exact match)
- [ ] Filtro por `actor_id` ou `actor_email`
- [ ] Filtro por `resource_type` e `resource_id`
- [ ] Filtro por `success` (boolean)
- [ ] Filtro por `from` e `to` (date range)
- [ ] Paginação cursor-based (limit, cursor)
- [ ] Ordenação por timestamp (desc default)

**API Contract**:
```http
GET /v1/events?
  action=user.created&
  actor_email=admin@example.com&
  from=2024-01-01T00:00:00Z&
  to=2024-01-31T23:59:59Z&
  limit=50&
  cursor=abc123
  
Response: 200 OK
{
  "data": [
    {
      "event_id": "uuid",
      "timestamp": "2024-01-15T10:30:00Z",
      "actor": { "id": "...", "email": "...", "type": "user" },
      "action": { "name": "user.created", "category": "identity" },
      "resource": { "type": "user", "id": "...", "name": "..." },
      "result": { "success": true }
    }
  ],
  "pagination": {
    "cursor": "next_cursor",
    "has_more": true
  },
  "total_count": 1234
}
```

---

### E4.S3 - Full-Text Search

| Field | Value |
|-------|-------|
| **Story ID** | E4.S3 |
| **Title** | Busca Full-Text |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Ana (Security Analyst)**, quero buscar eventos por texto livre, para encontrar rapidamente o que procuro.

**Acceptance Criteria**:
- [ ] Parâmetro `q` para busca textual
- [ ] Busca em: actor.email, actor.name, resource.name, error_message
- [ ] Fuzzy matching (typos)
- [ ] Highlighting nos resultados (opcional MVP)
- [ ] Query executada no OpenSearch

**API Contract**:
```http
GET /v1/events?q=password+reset&limit=20

Response: 200 OK
{
  "data": [
    {
      "event_id": "uuid",
      "action": { "name": "auth.password_reset" },
      ...
    }
  ]
}
```

---

### E4.S4 - Get Event by ID

| Field | Value |
|-------|-------|
| **Story ID** | E4.S4 |
| **Title** | Endpoint GET /v1/events/:id |
| **Priority** | P0 |
| **Points** | 3 |

**User Story**:
Como **Ana (Security Analyst)**, quero ver detalhes completos de um evento, para entender o contexto da ação.

**Acceptance Criteria**:
- [ ] `GET /v1/events/:id` retorna evento completo
- [ ] Inclui changes.before e changes.after
- [ ] Inclui metadata
- [ ] Resposta 404 se não encontrado
- [ ] Query no ClickHouse (source of truth)

---

### E4.S5 - Event Aggregations

| Field | Value |
|-------|-------|
| **Story ID** | E4.S5 |
| **Title** | Endpoint GET /v1/events/aggregations |
| **Priority** | P1 |
| **Points** | 5 |

**User Story**:
Como **Ana (Security Analyst)**, quero ver estatísticas agregadas, para entender padrões de atividade.

**Acceptance Criteria**:
- [ ] Contagem por action
- [ ] Contagem por período (hora, dia)
- [ ] Contagem de sucesso vs falha
- [ ] Filtros aplicáveis (date range, action, actor)
- [ ] Query no ClickHouse (otimizado)

**API Contract**:
```http
GET /v1/events/aggregations?
  group_by=action&
  from=2024-01-01&
  to=2024-01-31

Response: 200 OK
{
  "aggregations": [
    { "action": "auth.login", "count": 50000, "success": 49000, "failed": 1000 },
    { "action": "user.created", "count": 1200, "success": 1200, "failed": 0 }
  ],
  "total": 51200
}
```

---

### E4.S6 - Export to CSV

| Field | Value |
|-------|-------|
| **Story ID** | E4.S6 |
| **Title** | Export para CSV |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Carlos (Compliance Officer)**, quero exportar eventos para CSV, para anexar em relatórios de auditoria.

**Acceptance Criteria**:
- [ ] `GET /v1/events/export?format=csv`
- [ ] Mesmos filtros do list events
- [ ] Limite de 100K eventos por export
- [ ] Streaming response (não carregar tudo em memória)
- [ ] Headers adequados (Content-Disposition)

**API Contract**:
```http
GET /v1/events/export?
  format=csv&
  action=role.assigned&
  from=2024-01-01&
  to=2024-01-31

Response: 200 OK
Content-Type: text/csv
Content-Disposition: attachment; filename="audit-events-2024-01.csv"

event_id,timestamp,actor_email,action,resource_type,resource_id,success
uuid-1,2024-01-15T10:30:00Z,admin@example.com,role.assigned,user,uuid-2,true
...
```

---

### E4.S7 - Query Authorization

| Field | Value |
|-------|-------|
| **Story ID** | E4.S7 |
| **Title** | Autorização de Queries |
| **Priority** | P0 |
| **Points** | 3 |

**User Story**:
Como **Admin**, quero que queries sejam autorizadas, para que usuários vejam apenas dados permitidos.

**Acceptance Criteria**:
- [ ] API Key com scope `events:read` necessário
- [ ] Tenant filtering automático baseado na API Key
- [ ] Rate limiting em queries (separado de ingest)
- [ ] Logging de queries para auditoria

---

## 5. Dependencies

| Dependency | Type | Description |
|------------|------|-------------|
| E3.S2 | Internal | Dados no ClickHouse |
| E3.S3 | Internal | Dados no OpenSearch |
| E2.S2 | Internal | API Key authentication |

## 6. Definition of Done

- [ ] Todos endpoints funcionando
- [ ] Testes de integração passando
- [ ] Latência p95 < 2s
- [ ] Documentação OpenAPI
- [ ] Rate limiting configurado

---

**Status**: Draft  
**Created**: 2024-12-05
