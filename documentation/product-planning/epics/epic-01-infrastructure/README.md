# Epic 1: Infrastructure Foundation

> **"A house built on sand will not stand."**

---

## 1. Epic Overview

| Field | Value |
|-------|-------|
| **Epic ID** | E1 |
| **Epic Name** | Infrastructure Foundation |
| **Priority** | P0 - Critical Path |
| **Timeline** | Weeks 1-2 |
| **Owner** | Platform/SRE Team |

## 2. Objective

Estabelecer a infraestrutura base necessária para suportar a plataforma Turia Trails, incluindo clusters Kubernetes, bancos de dados, message broker e serviços de suporte.

## 3. Success Criteria

- [ ] Cluster Kubernetes configurado e operacional
- [ ] Redpanda cluster (3 nodes) funcionando
- [ ] ClickHouse cluster (3 nodes) funcionando
- [ ] OpenSearch cluster (3+3 nodes) funcionando
- [ ] PostgreSQL para metadata operacional
- [ ] Redis para cache e rate limiting
- [ ] Object Storage configurado
- [ ] Monitoramento básico (Prometheus/Grafana)
- [ ] Networking e security groups configurados

## 4. User Stories

### E1.S1 - Kubernetes Cluster Setup

| Field | Value |
|-------|-------|
| **Story ID** | E1.S1 |
| **Title** | Configurar Cluster Kubernetes |
| **Priority** | P0 |
| **Points** | 8 |

**User Story**:
Como **Administrador da Plataforma**, quero um cluster Kubernetes configurado com namespaces e RBAC, para que eu possa deployar os componentes do Turia Trails de forma isolada e segura.

**Acceptance Criteria**:
- [ ] Cluster K8s provisionado (3+ worker nodes)
- [ ] Namespace `turia-trails` criado
- [ ] RBAC configurado para team de desenvolvimento
- [ ] Storage classes para PVCs configuradas
- [ ] Ingress controller instalado (Nginx ou Traefik)
- [ ] Cert-manager para TLS automático
- [ ] Metrics server funcionando

**Technical Notes**:
- Considerar cluster self-managed
- Mínimo 3 worker nodes para HA
- Node pools separados para workloads stateful (databases)

---

### E1.S2 - Redpanda Cluster Setup

| Field | Value |
|-------|-------|
| **Story ID** | E1.S2 |
| **Title** | Deploy Redpanda Cluster |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Engenheiro de Plataforma**, quero um cluster Redpanda operacional, para que os eventos possam ser bufferizados de forma durável antes da persistência.

**Acceptance Criteria**:
- [ ] Cluster Redpanda com 3 brokers
- [ ] Replication factor = 3 configurado
- [ ] Topic `audit.events.v1` criado com 12 partições
- [ ] Topic `audit.events.dlq` para dead letters
- [ ] TLS habilitado para comunicação interna
- [ ] Metrics expostas para Prometheus
- [ ] Console/UI acessível para debugging

**Technical Notes**:
```yaml
# Specs por broker
resources:
  requests:
    cpu: 8
    memory: 32Gi
  limits:
    cpu: 8
    memory: 32Gi
storage:
  size: 1Ti
  storageClass: nvme-ssd
```

---

### E1.S3 - ClickHouse Cluster Setup

| Field | Value |
|-------|-------|
| **Story ID** | E1.S3 |
| **Title** | Deploy ClickHouse Cluster |
| **Priority** | P0 |
| **Points** | 8 |

**User Story**:
Como **Engenheiro de Dados**, quero um cluster ClickHouse configurado, para que os eventos de auditoria possam ser armazenados e consultados de forma eficiente.

**Acceptance Criteria**:
- [ ] Cluster ClickHouse com 3 nodes (1 shard × 3 replicas)
- [ ] Database `audit` criado
- [ ] Tabela `audit_events` com schema definido
- [ ] Materialized view para agregações horárias
- [ ] TTL configurado para 90 dias
- [ ] Users e permissões configurados
- [ ] Backup automático configurado

**Technical Notes**:
```yaml
# Specs por node
resources:
  requests:
    cpu: 16
    memory: 64Gi
storage:
  size: 2Ti
  storageClass: nvme-ssd
```

---

### E1.S4 - OpenSearch Cluster Setup

| Field | Value |
|-------|-------|
| **Story ID** | E1.S4 |
| **Title** | Deploy OpenSearch Cluster |
| **Priority** | P0 |
| **Points** | 8 |

**User Story**:
Como **Analista de Segurança**, quero um cluster OpenSearch para busca full-text, para que eu possa pesquisar eventos rapidamente usando termos de texto.

**Acceptance Criteria**:
- [ ] 3 data nodes + 3 master nodes
- [ ] Index template para `audit-events-*` criado
- [ ] ISM policy para rotação diária de índices
- [ ] Security plugin configurado
- [ ] OpenSearch Dashboards acessível
- [ ] Snapshot repository configurado (S3)

**Technical Notes**:
```yaml
# Specs por data node
resources:
  requests:
    cpu: 8
    memory: 32Gi
storage:
  size: 500Gi
  storageClass: nvme-ssd
```

---

### E1.S5 - PostgreSQL Setup

| Field | Value |
|-------|-------|
| **Story ID** | E1.S5 |
| **Title** | Deploy PostgreSQL para Metadata |
| **Priority** | P0 |
| **Points** | 3 |

**User Story**:
Como **Desenvolvedor Backend**, quero um PostgreSQL para armazenar metadata (API keys, configs, alertas), para que a aplicação tenha um store relacional confiável.

**Acceptance Criteria**:
- [ ] PostgreSQL 16 deployado (single instance ou HA)
- [ ] Database `turia_trails` criado
- [ ] Schemas: `public`, `auth`, `alerts`
- [ ] Connection pooling (PgBouncer) configurado
- [ ] Backup automático configurado
- [ ] Credentials em Kubernetes secrets

---

### E1.S6 - Redis Setup

| Field | Value |
|-------|-------|
| **Story ID** | E1.S6 |
| **Title** | Deploy Redis para Cache |
| **Priority** | P0 |
| **Points** | 2 |

**User Story**:
Como **Desenvolvedor Backend**, quero um Redis para cache e rate limiting, para que as operações de alta frequência sejam performáticas.

**Acceptance Criteria**:
- [ ] Redis 7 deployado
- [ ] Persistence habilitada (RDB + AOF)
- [ ] Maxmemory e eviction policy configurados
- [ ] Credentials em Kubernetes secrets

---

### E1.S7 - Object Storage Setup

| Field | Value |
|-------|-------|
| **Story ID** | E1.S7 |
| **Title** | Configurar Object Storage |
| **Priority** | P1 |
| **Points** | 2 |

**User Story**:
Como **Engenheiro de Plataforma**, quero buckets S3/Object Storage configurados, para armazenar backups e dados cold tier.

**Acceptance Criteria**:
- [ ] Bucket para backups do ClickHouse
- [ ] Bucket para snapshots do OpenSearch
- [ ] Bucket para cold storage (Parquet)
- [ ] Lifecycle policies configuradas
- [ ] Object Lock (WORM) habilitado para compliance
- [ ] IAM policies para acesso

---

### E1.S8 - Observability Stack

| Field | Value |
|-------|-------|
| **Story ID** | E1.S8 |
| **Title** | Setup Prometheus + Grafana |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **SRE**, quero monitoramento centralizado com Prometheus e Grafana, para que eu possa observar a saúde de todos os componentes.

**Acceptance Criteria**:
- [ ] Prometheus server deployado
- [ ] ServiceMonitors para todos os componentes
- [ ] Grafana com dashboards pré-configurados
- [ ] AlertManager configurado
- [ ] Alertas críticos definidos (disk, memory, lag)
- [ ] Retention de 15 dias de métricas

---

## 5. Dependencies

| Dependency | Type | Description |
|------------|------|-------------|
| Cloud Account | External | Acesso à cloud (AWS/GCP/MGC) |
| DNS | External | Domínio para endpoints |
| TLS Certificates | External | Wildcard cert ou Let's Encrypt |

## 6. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Sizing incorreto | High | Começar conservador, escalar depois |
| Complexidade de operação | Medium | Documentação detalhada, runbooks |
| Custos acima do esperado | Medium | Monitorar billing diariamente |

## 7. Definition of Done

- [ ] Todos os clusters operacionais e healthy
- [ ] Conectividade entre componentes testada
- [ ] Documentação de arquitetura atualizada
- [ ] Runbooks de operação criados
- [ ] Monitoramento com alertas funcionando
- [ ] Backup/restore testado

---

**Status**: Draft  
**Created**: 2024-12-05  
**Last Updated**: 2024-12-05
