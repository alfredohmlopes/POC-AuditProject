# Epic 3: Storage & Processing

> **"Store once, query many times."**

---

## 1. Epic Overview

| Field | Value |
|-------|-------|
| **Epic ID** | E3 |
| **Epic Name** | Storage & Processing |
| **Priority** | P0 - Critical Path |
| **Timeline** | Weeks 5-6 |
| **Owner** | Data Engineering Team |
| **Dependencies** | E1 (Infrastructure), E2 (Ingestion) |

## 2. Objective

Implementar os consumers que leem do Redpanda e persistem dados no ClickHouse (analytics) e OpenSearch (search), garantindo consistência e performance.

## 3. Success Criteria

- [ ] Consumer processando eventos do Redpanda
- [ ] Eventos persistidos no ClickHouse
- [ ] Eventos indexados no OpenSearch
- [ ] Lag de consumer < 1 minuto
- [ ] Zero data loss entre Redpanda e stores
- [ ] Retry e DLQ funcionando

## 4. User Stories

### E3.S1 - Vector Consumer Setup

| Field | Value |
|-------|-------|
| **Story ID** | E3.S1 |
| **Title** | Configurar Vector Consumer |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Engenheiro de Dados**, quero consumers lendo do Redpanda, para processar e persistir eventos nos stores.

**Acceptance Criteria**:
- [ ] Vector consumer deployado (3 réplicas)
- [ ] Consumer group configurado
- [ ] Offset commit automático
- [ ] Métricas de lag expostas
- [ ] Health check baseado em lag

---

### E3.S2 - ClickHouse Sink

| Field | Value |
|-------|-------|
| **Story ID** | E3.S2 |
| **Title** | Persistir Eventos no ClickHouse |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Engenheiro de Dados**, quero eventos persistidos no ClickHouse, para que estejam disponíveis para queries analíticas.

**Acceptance Criteria**:
- [ ] Sink ClickHouse configurado no Vector
- [ ] Bulk insert com batching (10K eventos ou 5s)
- [ ] Compression LZ4 habilitada
- [ ] Retry em caso de falha
- [ ] Métricas de insert rate

---

### E3.S3 - OpenSearch Sink

| Field | Value |
|-------|-------|
| **Story ID** | E3.S3 |
| **Title** | Indexar Eventos no OpenSearch |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Engenheiro de Dados**, quero eventos indexados no OpenSearch, para que estejam disponíveis para busca full-text.

**Acceptance Criteria**:
- [ ] Sink Elasticsearch (OpenSearch) configurado
- [ ] Bulk index com batching (5K docs ou 5s)
- [ ] Índices diários (`audit-events-YYYY-MM-DD`)
- [ ] Retry em caso de falha
- [ ] Métricas de index rate

---

### E3.S4 - Dead Letter Queue

| Field | Value |
|-------|-------|
| **Story ID** | E3.S4 |
| **Title** | Implementar Dead Letter Queue |
| **Priority** | P0 |
| **Points** | 3 |

**User Story**:
Como **Engenheiro de Dados**, quero eventos com falha enviados para DLQ, para análise e reprocessamento posterior.

**Acceptance Criteria**:
- [ ] Topic `audit.events.dlq` criado
- [ ] Eventos com falha de parsing → DLQ
- [ ] Eventos com falha de insert (após retries) → DLQ
- [ ] Alerta quando DLQ tem mensagens
- [ ] Processo de reprocessamento documentado

---

### E3.S5 - Index Lifecycle Management

| Field | Value |
|-------|-------|
| **Story ID** | E3.S5 |
| **Title** | Configurar ISM no OpenSearch |
| **Priority** | P1 |
| **Points** | 3 |

**User Story**:
Como **SRE**, quero políticas de lifecycle nos índices, para gerenciar storage automaticamente.

**Acceptance Criteria**:
- [ ] ISM policy criada
- [ ] Rollover diário de índices
- [ ] Force merge após 1 dia
- [ ] Delete após 7 dias (MVP)
- [ ] Snapshot antes de delete

---

### E3.S6 - ClickHouse Data Quality

| Field | Value |
|-------|-------|
| **Story ID** | E3.S6 |
| **Title** | Validar Qualidade de Dados |
| **Priority** | P1 |
| **Points** | 3 |

**User Story**:
Como **Engenheiro de Dados**, quero métricas de qualidade dos dados, para garantir integridade.

**Acceptance Criteria**:
- [ ] Query para contar eventos por hora (reconciliação)
- [ ] Alert se diferença > 1% entre Redpanda e ClickHouse
- [ ] Dashboard com métricas de ingestão
- [ ] Verificação de duplicatas

---

## 5. Dependencies

| Dependency | Type | Description |
|------------|------|-------------|
| E1.S2 | Internal | Redpanda cluster |
| E1.S3 | Internal | ClickHouse cluster |
| E1.S4 | Internal | OpenSearch cluster |
| E2.S7 | Internal | Events no Redpanda |

## 6. Definition of Done

- [ ] Consumer lag < 1 minuto em steady state
- [ ] Zero data loss verificado
- [ ] DLQ funcionando
- [ ] Métricas e alertas configurados
- [ ] Documentação de operação

---

**Status**: Draft  
**Created**: 2024-12-05
