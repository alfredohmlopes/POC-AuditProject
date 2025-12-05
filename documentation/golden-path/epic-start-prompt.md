# Epic Start Prompt - Golden Path Template

> **Purpose**: Este template deve ser executado **ANTES** de iniciar qualquer novo Epic para garantir planejamento adequado e alinhamento com os Golden Path standards.

---

## 🎯 Epic Kickoff Checklist

### 1. Epic Definition Review

Antes de começar, revise e confirme:

- [ ] **Epic ID e Nome** claramente definidos
- [ ] **Goal** do epic está alinhado com objetivos de negócio
- [ ] **Success Criteria** são mensuráveis e específicos
- [ ] **Sprint allocation** está realista (considere buffer de 20%)
- [ ] **Personas** afetadas estão identificadas (Sarah, Maria, Alex)

### 2. Análise de Dependências

Verifique dependências técnicas e de negócio:

- [ ] **Epics predecessores** completados e validados
- [ ] **Infraestrutura necessária** disponível (DB, cache, IDP)
- [ ] **APIs externas** documentadas e testadas
- [ ] **Bibliotecas/frameworks** escolhidos e aprovados
- [ ] **Bloqueadores conhecidos** documentados e plano de mitigação criado

### 3. Technical Design Document (TDD)

Crie um TDD antes de codificar:

```markdown
# Epic [ID]: [Nome] - Technical Design

## 1. Context & Goals
- What: [O que estamos construindo]
- Why: [Por que é necessário]
- Who: [Quem vai usar]

## 2. Architecture
- [ ] Diagrama de componentes (mermaid)
- [ ] Diagrama de sequência para fluxos principais
- [ ] Decisões de design (ADRs)

## 3. Data Model
- [ ] Entity-Relationship Diagram
- [ ] Migration scripts planejados
- [ ] Índices de performance identificados

## 4. API Contract
- [ ] OpenAPI spec (YAML)
- [ ] Request/Response examples
- [ ] Error codes definidos

## 5. Security Considerations
- [ ] Authentication/Authorization strategy
- [ ] Input validation rules
- [ ] Rate limiting configurado
- [ ] Audit logging planejado

## 6. Test Strategy
- [ ] Unit test plan (≥80% coverage)
- [ ] Integration test scenarios
- [ ] Performance test targets (p95 < Xms)
```

### 4. Golden Path Compliance Check

Revise cada seção do Golden Path e marque ações necessárias:

#### 4.1 Architecture Golden Path
- [ ] **Clean Architecture**: Camadas Domain → Service → Repository → Infra definidas
- [ ] **Dependency Rule**: Dependencies apontam para dentro (Core não depende de Infra)
- [ ] **SOLID Principles**: Revisar Single Responsibility, Open/Closed, Liskov, Interface Segregation, Dependency Inversion
- [ ] **Repository Pattern**: Interface no Domain, implementação no Infra
- [ ] **Error Handling**: Erros customizados no Domain, wrapping no Service

#### 4.2 Security Golden Path
- [ ] **Input Validation**: Todas entradas validadas (SQL injection, XSS prevention)
- [ ] **Authentication**: JWT RS256 com public key validation
- [ ] **Authorization**: RBAC middleware aplicado em todos endpoints protegidos
- [ ] **Password Security**: Argon2id ou PBKDF2, min 12 chars, zxcvbn score ≥ 3
- [ ] **Rate Limiting**: Configurado por endpoint (defaults: 100 req/min)
- [ ] **Secrets Management**: Nenhum secret hardcoded, usar env vars

#### 4.3 Auditing Golden Path
- [ ] **What to Audit**: Mapear todas ações state-changing
- [ ] **Audit Schema**: WHO (user_id), WHAT (action), WHEN (timestamp), WHERE (ip_address), METADATA (changes)
- [ ] **Storage**: PostgreSQL com tabela `audit_events`
- [ ] **Retention**: Mínimo 1 ano
- [ ] **GDPR Compliance**: Plano para Right to Access e Right to Erasure

#### 4.4 Quality Golden Path
- [ ] **Test Pyramid**: 70% unit, 20% integration, 10% e2e planejado
- [ ] **Unit Tests**: Table-driven tests, mocks para dependencies
- [ ] **Integration Tests**: Testcontainers para DB/Redis/Keycloak
- [ ] **Code Coverage**: Target ≥80% overall, ≥90% para critical paths
- [ ] **Linting**: RuboCop configurado, zero offenses antes de merge
- [ ] **Performance Benchmarks**: Definir targets (ex: p95 < 200ms)

#### 4.5 Development Golden Path
- [ ] **Git Workflow**: Feature branches, trunk-based development
- [ ] **Commit Messages**: Conventional Commits (feat:, fix:, docs:, etc)
- [ ] **Pull Requests**: Template pronto, reviewers assinalados
- [ ] **i18n**: Todas mensagens user-facing em translation keys
- [ ] **Database Migrations**: Rails migrations, up/down scripts, testados em dev

#### 4.6 UX Golden Path
- [ ] **User-Centric**: Design centrado nas personas (Sarah, Maria, Alex)
- [ ] **Simplicity**: Fluxos com ≤5 passos
- [ ] **Consistency**: Seguir padrões da biblioteca (shadcn/ui)
- [ ] **Accessibility**: WCAG 2.1 AA compliance planejado
- [ ] **Error Handling**: Mensagens amigáveis, sugestões de ação
- [ ] **Empty States**: Designs prontos, CTAs claros

---

## 5. Implementation Plan

Crie um plano de execução detalhado:

### Sprint Breakdown

| Story | Effort | Dependencies | Owner | Sprint |
|-------|--------|-------------|-------|--------|
| E[X].1 | 3 days | None | [Dev] | Sprint N |
| E[X].2 | 5 days | E[X].1 | [Dev] | Sprint N+1 |
| E[X].3 | 2 days | E[X].2 | [Dev] | Sprint N+1 |

### Daily Tasks (Exemplo para E[X].1)

**Day 1**:
- [ ] Criar migrations (users table)
- [ ] Definir Domain entities (User, UserRepository interface)
- [ ] Escrever unit tests para entities

**Day 2**:
- [ ] Implementar Repository (PostgreSQL)
- [ ] Escrever integration tests para repository
- [ ] Implementar Service layer (CreateUser, ListUsers)

**Day 3**:
- [ ] Implementar HTTP handlers
- [ ] Adicionar RBAC middleware
- [ ] Escrever handler tests
- [ ] Code review e merge

---

## 6. Definition of Done (DoD)

Antes de marcar o Epic como completo, verificar:

### Code Quality
- [ ] Todos testes passando (`bundle exec rspec`)
- [ ] Coverage ≥80% (SimpleCov)
- [ ] Linting zero warnings (`bundle exec rubocop`)
- [ ] Nenhum TODO ou FIXME sem issue linkado

### Security
- [ ] Input validation implementada
- [ ] Authentication/Authorization funcionando
- [ ] Nenhum secret commitado (`git secrets` scan)
- [ ] SQL injection prevention (parameterized queries)

### Testing
- [ ] Unit tests com mocks
- [ ] Integration tests com testcontainers
- [ ] E2E tests (se aplicável)
- [ ] Performance tests (load test básico)

### Auditing
- [ ] Audit logs para state-changing actions
- [ ] Logs incluem WHO, WHAT, WHEN, WHERE

### Documentation
- [ ] OpenAPI spec atualizado
- [ ] README atualizado (se aplicável)
- [ ] ADRs documentadas
- [ ] Changelog atualizado

### Review
- [ ] Peer review aprovado (≥2 approvers)
- [ ] Security review (se mudanças auth/crypto)
- [ ] Design review (se mudanças UI/UX)

---

## 7. Risk Assessment

Identifique riscos potenciais:

| Risco | Impacto | Probabilidade | Mitigação |
|-------|---------|---------------|-----------|
| Ex: Performance degradation | Alto | Baixa | Adicionar índices DB, cache Redis |
| Ex: Breaking change API | Médio | Média | Versionar API, comunicar deprecation |

---

## 8. Communication Plan

- [ ] **Kickoff meeting** agendado (team + stakeholders)
- [ ] **Daily standups** agendados (15 min, async via Slack)
- [ ] **Sprint review** agendado (demo + feedback)
- [ ] **Sprint retrospective** agendado (lições aprendidas)

---

## 9. Success Metrics

Defina como medir sucesso:

- [ ] **Functional**: Todos acceptance criteria passando
- [ ] **Performance**: p95 latency < [X]ms
- [ ] **Quality**: Code coverage ≥80%
- [ ] **Security**: Zero vulnerabilities críticas (Snyk/Trivy scan)
- [ ] **UX**: [Metric específica, ex: Time to complete task < 2 min]

---

## 10. Approval Checkpoints

Antes de iniciar desenvolvimento:

- [ ] **Tech Lead Approval**: Design técnico revisado
- [ ] **Security Team Approval**: Riscos de segurança mitigados
- [ ] **Product Owner Approval**: Stories priorizadas e acceptance criteria acordados

---

## ✅ Ready to Start

Se todos os checkboxes acima estão marcados, você está pronto para iniciar o Epic!

**Next Steps**:
1. Criar branch feature do Epic: `git checkout -b epic/[epic-id]-[epic-name]`
2. Atualizar `documentation/product-planning/initiative-progress.md` com status "Em Progresso"
3. Começar primeira story conforme plano de execução

---

**Good luck! 🚀**
