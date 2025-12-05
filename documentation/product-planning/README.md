# Turia Trails MVP - Product Planning

> **"Planejar é trazer o futuro para o presente, para que você possa fazer algo a respeito agora."**  
> — Alan Lakein

---

## 1. Epic Overview

| Epic | Name | Stories | Timeline | Priority | Dependencies |
|------|------|---------|----------|----------|--------------|
| **E1** | [Infrastructure Foundation](./epics/epic-01-infrastructure/README.md) | 8 | Weeks 1-2 | P0 | - |
| **E2** | [Ingestion Pipeline](./epics/epic-02-ingestion/README.md) | 9 | Weeks 3-4 | P0 | E1 |
| **E3** | [Storage & Processing](./epics/epic-03-storage/README.md) | 6 | Weeks 5-6 | P0 | E1, E2 |
| **E4** | [Query API](./epics/epic-04-query-api/README.md) | 7 | Weeks 7-8 | P0 | E3 |
| **E5** | [Dashboard](./epics/epic-05-dashboard/README.md) | 10 | Weeks 9-12 | P0 | E4 |
| **E6** | [Alerting](./epics/epic-06-alerting/README.md) | 10 | Weeks 13-14 | P0 | E3, E5 |
| **E7** | [SDK & Integration](./epics/epic-07-sdk/README.md) | 10 | Weeks 7-8 | P0 | E2 |

**Total Stories**: 60

---

## 2. Timeline (16 Weeks)

```
Week 1-2    Week 3-4    Week 5-6    Week 7-8    Week 9-12   Week 13-14  Week 15-16
   │           │           │           │           │           │           │
   ▼           ▼           ▼           ▼           ▼           ▼           ▼
┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐  ┌───────────┐ ┌───────┐  ┌───────┐
│  E1   │  │  E2   │  │  E3   │  │  E4   │  │    E5     │ │  E6   │  │ Polish│
│Infra  │─▸│Ingest │─▸│Storage│─▸│ Query │─▸│ Dashboard │─▸│Alerts │─▸│ Test  │
│       │  │       │  │       │  │       │  │           │ │       │  │ Deploy│
└───────┘  └───────┘  └───────┘  └───────┘  └───────────┘ └───────┘  └───────┘
                                    │
                               ┌────┴────┐
                               │   E7    │
                               │  SDK    │
                               │  Pilot  │
                               └─────────┘
                               Week 7-8 (parallel)
```

---

## 3. Story Summary by Epic

### E1: Infrastructure Foundation (8 stories, 36 points)

| Story | Title | Priority | Points |
|-------|-------|----------|--------|
| E1.S1 | Kubernetes Cluster Setup | P0 | 8 |
| E1.S2 | Redpanda Cluster Setup | P0 | 5 |
| E1.S3 | ClickHouse Cluster Setup | P0 | 8 |
| E1.S4 | OpenSearch Cluster Setup | P0 | 8 |
| E1.S5 | PostgreSQL Setup | P0 | 3 |
| E1.S6 | Redis Setup | P0 | 2 |
| E1.S7 | Object Storage Setup | P1 | 2 |
| E1.S8 | Observability Stack | P0 | 5 |

---

### E2: Ingestion Pipeline (9 stories, 39 points)

| Story | Title | Priority | Points |
|-------|-------|----------|--------|
| E2.S1 | APISIX Gateway Setup | P0 | 5 |
| E2.S2 | API Key Authentication | P0 | 5 |
| E2.S3 | Rate Limiting | P0 | 3 |
| E2.S4 | Vector HTTP Source | P0 | 5 |
| E2.S5 | Event Schema Validation | P0 | 5 |
| E2.S6 | Event Enrichment | P1 | 3 |
| E2.S7 | Redpanda Producer | P0 | 5 |
| E2.S8 | Single Event Endpoint | P0 | 3 |
| E2.S9 | Batch Event Endpoint | P0 | 5 |

---

### E3: Storage & Processing (6 stories, 24 points)

| Story | Title | Priority | Points |
|-------|-------|----------|--------|
| E3.S1 | Vector Consumer Setup | P0 | 5 |
| E3.S2 | ClickHouse Sink | P0 | 5 |
| E3.S3 | OpenSearch Sink | P0 | 5 |
| E3.S4 | Dead Letter Queue | P0 | 3 |
| E3.S5 | Index Lifecycle Management | P1 | 3 |
| E3.S6 | ClickHouse Data Quality | P1 | 3 |

---

### E4: Query API (7 stories, 32 points)

| Story | Title | Priority | Points |
|-------|-------|----------|--------|
| E4.S1 | Query Service Setup | P0 | 5 |
| E4.S2 | List Events Endpoint | P0 | 8 |
| E4.S3 | Full-Text Search | P0 | 5 |
| E4.S4 | Get Event by ID | P0 | 3 |
| E4.S5 | Event Aggregations | P1 | 5 |
| E4.S6 | Export to CSV | P0 | 5 |
| E4.S7 | Query Authorization | P0 | 3 |

---

### E5: Dashboard (10 stories, 45 points)

| Story | Title | Priority | Points |
|-------|-------|----------|--------|
| E5.S1 | Project Setup | P0 | 3 |
| E5.S2 | Authentication (SSO) | P0 | 5 |
| E5.S3 | Event List Page | P0 | 8 |
| E5.S4 | Search Bar | P0 | 5 |
| E5.S5 | Filter Panel | P0 | 5 |
| E5.S6 | Event Detail Page | P0 | 5 |
| E5.S7 | Export CSV | P0 | 3 |
| E5.S8 | Settings Page | P1 | 5 |
| E5.S9 | Responsive Design | P1 | 3 |
| E5.S10 | Error Handling & Loading | P0 | 3 |

---

### E6: Alerting (10 stories, 43 points)

| Story | Title | Priority | Points |
|-------|-------|----------|--------|
| E6.S1 | Alert Engine Setup | P0 | 8 |
| E6.S2 | Alert Rule Schema | P0 | 5 |
| E6.S3 | Brute Force Alert | P0 | 5 |
| E6.S4 | Admin Role Grant Alert | P0 | 3 |
| E6.S5 | Mass Deletion Alert | P0 | 3 |
| E6.S6 | Off-Hours Alert | P1 | 3 |
| E6.S7 | Email Notifications | P0 | 5 |
| E6.S8 | Slack Notifications | P0 | 5 |
| E6.S9 | Alert History | P1 | 5 |
| E6.S10 | Alert Dashboard Widget | P1 | 3 |

---

### E7: SDK & Integration (10 stories, 60 points)

| Story | Title | Priority | Points |
|-------|-------|----------|--------|
| E7.S1 | SDK Core Design | P0 | 5 |
| E7.S2 | SDK Primary Language | P0 | 13 |
| E7.S3 | Auto Context Capture | P0 | 5 |
| E7.S4 | Buffering & Batching | P0 | 5 |
| E7.S5 | Retry & Resilience | P0 | 5 |
| E7.S6 | SDK Documentation | P0 | 5 |
| E7.S7 | Integration Examples | P1 | 5 |
| E7.S8 | Pilot Integration #1 (ID Magalu) | P0 | 8 |
| E7.S9 | Pilot Integration #2 (RBAC) | P0 | 8 |
| E7.S10 | OpenAPI Specification | P1 | 3 |

---

## 4. Total Effort

| Metric | Value |
|--------|-------|
| **Total Epics** | 7 |
| **Total Stories** | 60 |
| **Total Story Points** | 279 |
| **P0 Stories** | 47 |
| **P1 Stories** | 13 |
| **Estimated Duration** | 16 weeks |

### Team Velocity Assumption

Assumindo um velocity de ~18 pontos por sprint (2 semanas):

```
Sprint 1  (W1-2):  E1 parcial         ~18 pts
Sprint 2  (W3-4):  E1 final + E2      ~18 pts
Sprint 3  (W5-6):  E2 final + E3      ~18 pts
Sprint 4  (W7-8):  E4 + E7 inicio     ~18 pts
Sprint 5  (W9-10): E5 inicio          ~18 pts
Sprint 6  (W11-12): E5 final          ~18 pts
Sprint 7  (W13-14): E6 + E7 final     ~18 pts
Sprint 8  (W15-16): Polish + Launch   buffer
```

---

## 5. Dependencies Graph

```
                                    ┌─────────┐
                                    │   E1    │
                                    │  Infra  │
                                    └────┬────┘
                                         │
                                         ▼
                                    ┌─────────┐
                                    │   E2    │
                                    │ Ingest  │
                                    └────┬────┘
                                         │
                        ┌────────────────┼────────────────┐
                        │                │                │
                        ▼                ▼                ▼
                   ┌─────────┐      ┌─────────┐      ┌─────────┐
                   │   E3    │      │   E7    │      │         │
                   │ Storage │      │   SDK   │      │         │
                   └────┬────┘      └────┬────┘      │         │
                        │                │           │         │
                        ▼                ▼           │         │
                   ┌─────────┐      ┌─────────┐      │         │
                   │   E4    │      │ Pilots  │      │         │
                   │  Query  │      └─────────┘      │         │
                   └────┬────┘                       │         │
                        │                            │         │
                        ▼                            │         │
                   ┌─────────┐                       │         │
                   │   E5    │◄──────────────────────┘         │
                   │Dashboard│                                 │
                   └────┬────┘                                 │
                        │                                      │
                        ▼                                      │
                   ┌─────────┐                                 │
                   │   E6    │◄────────────────────────────────┘
                   │ Alerts  │
                   └─────────┘
```

---

## 6. Milestones

| Milestone | Date (approx) | Deliverables |
|-----------|---------------|--------------|
| **M1: Infra Ready** | Week 2 | All clusters operational |
| **M2: Ingestion Working** | Week 4 | Events flowing to Redpanda |
| **M3: Storage Complete** | Week 6 | Data in ClickHouse + OpenSearch |
| **M4: Query API + SDK** | Week 8 | API functional, SDK released |
| **M5: Dashboard Alpha** | Week 10 | Basic UI functional |
| **M6: Dashboard Beta** | Week 12 | Full UI with filters/export |
| **M7: Alerting Live** | Week 14 | 5 alerts, Email + Slack |
| **M8: MVP Launch** | Week 16 | Production ready |

---

## 7. Risks & Mitigations

| Risk | Impact | Prob | Mitigation |
|------|--------|------|------------|
| Infrastructure delays | High | Med | Start infra setup immediately, buffer time |
| Pilot teams unavailable | High | Med | Identify backup pilots, mockup integration |
| OpenSearch complexity | Med | Med | Consider managed option, dedicated expert |
| Dashboard scope creep | Med | High | Strict MVP features only, P1s for v1.5 |
| Performance issues | High | Low | Load test early (week 4), iterate |

---

## 8. Next Steps

1. **Priorizar SDK language**: Go, Ruby, Python, or Node.js?
2. **Confirmar produtos piloto**: ID Magalu + RBAC disponíveis?
3. **Alocar equipe**: Backend, Frontend, SRE, Data
4. **Sprint 0**: Kick-off, refinement, ambiente dev

---

**Status**: Ready for Review  
**Created**: 2024-12-05  
**Last Updated**: 2024-12-05
