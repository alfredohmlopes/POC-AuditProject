# Epic 7: SDK & Integration

> **"Make it easy to do the right thing."**

---

## 1. Epic Overview

| Field | Value |
|-------|-------|
| **Epic ID** | E7 |
| **Epic Name** | SDK & Integration |
| **Priority** | P0 - Critical Path |
| **Timeline** | Weeks 7-8 (parallel com E4) |
| **Owner** | Backend Team |
| **Dependencies** | E2 (Ingestion API) |

## 2. Objective

Desenvolver SDKs que facilitem a integração de produtos com o Turia Trails, começando com a linguagem prioritária do time.

## 3. Success Criteria

- [ ] SDK primário publicado (Go, Ruby, ou Python)
- [ ] Documentação de integração completa
- [ ] Exemplo de integração funcionando
- [ ] 2 produtos piloto integrados
- [ ] Tempo de integração < 1 dia

## 4. User Stories

### E7.S1 - SDK Core Design

| Field | Value |
|-------|-------|
| **Story ID** | E7.S1 |
| **Title** | Design do SDK Core |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Marina (Platform Engineer)**, quero um SDK bem projetado, para integrar facilmente sem ler muita documentação.

**Acceptance Criteria**:
- [ ] Interface pública definida
- [ ] Configuração via environment variables
- [ ] Builder pattern para eventos
- [ ] Async por default (não bloqueia)
- [ ] Error handling claro

**Interface Example (Go)**:
```go
// Configuration
client := turia.NewClient(turia.Config{
    APIKey:      os.Getenv("TURIA_API_KEY"),
    ServiceName: "user-management",
    Environment: "production",
})

// Log event
client.LogEvent(ctx, turia.Event{
    Action:   "user.created",
    Actor:    turia.Actor{ID: userID, Type: "user", Email: email},
    Resource: turia.Resource{Type: "user", ID: newUserID},
    Success:  true,
})
```

---

### E7.S2 - SDK Primary Language

| Field | Value |
|-------|-------|
| **Story ID** | E7.S2 |
| **Title** | SDK na Linguagem Principal |
| **Priority** | P0 |
| **Points** | 13 |

**User Story**:
Como **Marina (Platform Engineer)**, quero um SDK na linguagem do meu projeto, para integrar nativamente.

**Acceptance Criteria**:
- [ ] SDK publicado (escolher: Go, Ruby, Python, ou Node.js)
- [ ] Async/non-blocking por default
- [ ] Buffer local com flush automático
- [ ] Retry com exponential backoff
- [ ] Graceful degradation (falha silenciosa)
- [ ] Context propagation (trace IDs)
- [ ] Type-safe event builder
- [ ] Testes unitários (> 80% coverage)

**Features Obrigatórias**:
1. `client.LogEvent()` - single event
2. `client.LogBatch()` - batch events
3. `client.Flush()` - force flush buffer
4. `client.Close()` - graceful shutdown

---

### E7.S3 - Auto Context Capture

| Field | Value |
|-------|-------|
| **Story ID** | E7.S3 |
| **Title** | Captura Automática de Contexto |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Marina (Platform Engineer)**, quero que o SDK capture contexto automaticamente, para não precisar passar manualmente.

**Acceptance Criteria**:
- [ ] IP address (de request, se disponível)
- [ ] User agent (de request, se disponível)
- [ ] Request ID / Trace ID (se disponível)
- [ ] Timestamp gerado automaticamente
- [ ] Service name e version da config

**Example (HTTP Middleware)**:
```go
// Go middleware example
func TuriaMiddleware(client *turia.Client) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            ctx := turia.WithContext(r.Context(), turia.RequestContext{
                IP:        r.RemoteAddr,
                UserAgent: r.UserAgent(),
                RequestID: r.Header.Get("X-Request-ID"),
            })
            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}
```

---

### E7.S4 - Buffering & Batching

| Field | Value |
|-------|-------|
| **Story ID** | E7.S4 |
| **Title** | Buffer Local e Batching |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Marina (Platform Engineer)**, quero que o SDK agrupe eventos, para otimizar performance da minha aplicação.

**Acceptance Criteria**:
- [ ] Buffer in-memory com limite configurável (default 100 eventos)
- [ ] Flush automático a cada N segundos (default 5s)
- [ ] Flush automático quando buffer cheio
- [ ] Flush on shutdown (graceful)
- [ ] Configuração de batch size (máximo 1000)

---

### E7.S5 - Retry & Resilience

| Field | Value |
|-------|-------|
| **Story ID** | E7.S5 |
| **Title** | Retry e Resiliência |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Marina (Platform Engineer)**, quero que o SDK lide com falhas graciosamente, para não impactar minha aplicação.

**Acceptance Criteria**:
- [ ] Retry com exponential backoff (1s, 2s, 4s, max 30s)
- [ ] Máximo de 3 retries
- [ ] Circuit breaker após falhas consecutivas
- [ ] Fallback: log local se tudo falhar
- [ ] Nunca bloquear a aplicação principal
- [ ] Métricas de sucesso/falha expostas

---

### E7.S6 - SDK Documentation

| Field | Value |
|-------|-------|
| **Story ID** | E7.S6 |
| **Title** | Documentação do SDK |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Marina (Platform Engineer)**, quero documentação clara, para integrar em menos de 1 dia.

**Acceptance Criteria**:
- [ ] README com quick start
- [ ] Installation guide
- [ ] Configuration reference
- [ ] API reference completa
- [ ] Examples para casos comuns
- [ ] Troubleshooting section
- [ ] Changelog

---

### E7.S7 - Integration Examples

| Field | Value |
|-------|-------|
| **Story ID** | E7.S7 |
| **Title** | Exemplos de Integração |
| **Priority** | P1 |
| **Points** | 5 |

**User Story**:
Como **Marina (Platform Engineer)**, quero exemplos funcionais, para copiar e adaptar.

**Acceptance Criteria**:
- [ ] Exemplo básico (minimal)
- [ ] Exemplo com web framework (Gin/Rails/FastAPI)
- [ ] Exemplo com middleware/interceptor
- [ ] Exemplo de auditoria de CRUD
- [ ] Repositório público com exemplos

---

### E7.S8 - Pilot Integration #1

| Field | Value |
|-------|-------|
| **Story ID** | E7.S8 |
| **Title** | Integração Piloto - ID Magalu |
| **Priority** | P0 |
| **Points** | 8 |

**User Story**:
Como **Stakeholder**, quero o ID Magalu integrado, para validar o Turia Trails com dados reais.

**Acceptance Criteria**:
- [ ] SDK integrado no ID Magalu
- [ ] Eventos de login (success/failure)
- [ ] Eventos de registro
- [ ] Eventos de MFA
- [ ] Validação de eventos chegando no dashboard
- [ ] Performance não impactada (< 5ms overhead)

---

### E7.S9 - Pilot Integration #2

| Field | Value |
|-------|-------|
| **Story ID** | E7.S9 |
| **Title** | Integração Piloto - RBAC |
| **Priority** | P0 |
| **Points** | 8 |

**User Story**:
Como **Stakeholder**, quero o RBAC integrado, para auditar mudanças de permissão.

**Acceptance Criteria**:
- [ ] SDK integrado no RBAC Service
- [ ] Eventos de role.assigned / role.removed
- [ ] Eventos de permission.granted / permission.revoked
- [ ] Changes (before/after) capturados
- [ ] Validação de eventos no dashboard

---

### E7.S10 - OpenAPI Specification

| Field | Value |
|-------|-------|
| **Story ID** | E7.S10 |
| **Title** | OpenAPI Specification |
| **Priority** | P1 |
| **Points** | 3 |

**User Story**:
Como **Marina (Platform Engineer)**, quero uma especificação OpenAPI, para gerar clientes automaticamente.

**Acceptance Criteria**:
- [ ] Spec OpenAPI 3.0 completa
- [ ] Todos os endpoints documentados
- [ ] Schemas para request/response
- [ ] Exemplos para cada endpoint
- [ ] Publicada e acessível

---

## 5. Dependencies

| Dependency | Type | Description |
|------------|------|-------------|
| E2.S8 | Internal | Single event endpoint |
| E2.S9 | Internal | Batch event endpoint |
| ID Magalu | External | Acesso para integração |
| RBAC Service | External | Acesso para integração |

## 6. SDK Feature Matrix

| Feature | MVP | v1.5 | v2.0 |
|---------|-----|------|------|
| Single event | ✓ | ✓ | ✓ |
| Batch events | ✓ | ✓ | ✓ |
| Auto context | ✓ | ✓ | ✓ |
| Buffering | ✓ | ✓ | ✓ |
| Retry | ✓ | ✓ | ✓ |
| Circuit breaker | ✓ | ✓ | ✓ |
| Metrics export | - | ✓ | ✓ |
| OpenTelemetry | - | ✓ | ✓ |
| Middleware/Interceptor | - | ✓ | ✓ |

## 7. Definition of Done

- [ ] SDK publicado e documentado
- [ ] 2 produtos piloto integrados
- [ ] Eventos chegando no dashboard
- [ ] Performance validada (< 5ms overhead)
- [ ] Documentação completa

---

**Status**: Draft  
**Created**: 2024-12-05
