# Epic Review Prompt - Golden Path Template

> **Purpose**: Este template deve ser executado **AO TÉRMINO** de cada Epic para avaliar a entrega, identificar melhorias e capturar lições aprendidas.

---

## 📊 Epic Completion Review

### Epic Information

- **Epic ID**: [Ex: E3]
- **Epic Name**: [Ex: User Management API]
- **Sprint(s)**: [Ex: Sprint 4-5]
- **Completion Date**: [YYYY-MM-DD]
- **Team Members**: [Lista de contribuidores]

---

## ✅ Delivery Verification

### 1. Acceptance Criteria Review

Revise cada story e marque se foi completamente entregue:

| Story ID | Story Name | Status | Notes |
|----------|------------|--------|-------|
| E[X].1 | [Nome] | ✅ / ⚠️ / ❌ | [Comentários] |
| E[X].2 | [Nome] | ✅ / ⚠️ / ❌ | [Comentários] |
| E[X].3 | [Nome] | ✅ / ⚠️ / ❌ | [Comentários] |

**Legend**:
- ✅ Completamente entregue
- ⚠️ Entregue com limitações (documentar)
- ❌ Não entregue (criar follow-up story)

### 2. Definition of Done Compliance

Verifique se todos os itens do DoD foram cumpridos:

#### Code Quality
- [ ] Todos testes passando (`bundle exec rspec`)
- [ ] Coverage ≥80% (SimpleCov report)
- [ ] Linting zero warnings (`bundle exec rubocop`)
- [ ] Nenhum hardcoded value (usar constants ou config)

#### Security
- [ ] Input validation implementada
- [ ] Authentication/Authorization funcionando
- [ ] Secrets scan passou (`git secrets --scan`)
- [ ] SQL injection prevention (parameterized queries)

#### Testing
- [ ] Unit tests escritos (≥70% do total)
- [ ] Integration tests escritos (≥20% do total)
- [ ] E2E tests escritos (≥10% do total)
- [ ] Performance tests executados (load test report)

#### Auditing
- [ ] State-changing actions logadas
- [ ] Audit logs incluem WHO, WHAT, WHEN, WHERE

#### Documentation
- [ ] OpenAPI spec atualizado (100% endpoints)
- [ ] README atualizado (se aplicável)
- [ ] CHANGELOG atualizado
- [ ] ADRs documentadas (se design decisions importantes)

#### Review
- [ ] Peer review completado (≥2 approvers)
- [ ] Security review completado (se auth/crypto changes)
- [ ] CI/CD pipeline passou (all checks green)

---

## 📈 Metrics Analysis

### 3. Performance Metrics

Capture métricas reais vs targets:

| Métrica | Target | Atual | Status | Notas |
|---------|--------|-------|--------|-------|
| **Code Coverage** | ≥80% | [X]% | ✅/❌ | |
| **API Latency (p95)** | <200ms | [X]ms | ✅/❌ | |
| **Load Test (RPS)** | 1000 rps | [X] rps | ✅/❌ | |
| **Bug Count (P0/P1)** | 0 | [X] | ✅/❌ | |
| **Security Vulnerabilities** | 0 critical | [X] | ✅/❌ | |

### 4. Quality Metrics

```bash
# Run these commands and document results:

# 1. Test Coverage
bundle exec rspec
open coverage/index.html
# Result: X% coverage

# 2. Cyclomatic Complexity
bundle exec rubocop --format json | jq '.files[].offenses[] | select(.cop_name | contains("Metrics"))'
# Result: X violations

# 3. Code Duplication
bundle exec flay app/
# Result: X duplicate blocks

# 4. Lint Warnings
bundle exec rubocop
# Result: X offenses

# 5. Security Scan
bundle exec brakeman -q
bundle audit check
# Result: X vulnerabilities
```

---

## 🔍 Golden Path Compliance Audit

### 5. Architecture Golden Path Compliance

- [ ] **Clean Architecture**: Dependency Rule respeitada (Core não depende de Infra)
- [ ] **SOLID Principles**: Code review confirma aderência
- [ ] **Repository Pattern**: Interfaces no Domain, implementações no Infra
- [ ] **Error Handling**: Erros customizados, wrapping apropriado

**Score**: ⭐⭐⭐⭐⭐ (5/5) ou ⭐⭐⭐⭐☆ (4/5)

**Gaps Identificados**:
- [Lista gaps específicos, ex: "Service X tem dependency direta em DB"]

**Action Items**:
- [ ] [Criar issue para refatorar Service X]

---

### 6. Security Golden Path Compliance

- [ ] **Input Validation**: Todas entradas validadas (SQL injection, XSS)
- [ ] **Authentication**: JWT RS256 funcionando
- [ ] **Authorization**: RBAC aplicado em todos endpoints protegidos
- [ ] **Password Security**: Argon2id/PBKDF2, min 12 chars
- [ ] **Rate Limiting**: Configurado e testado
- [ ] **Secrets Management**: Nenhum secret hardcoded

**Score**: ⭐⭐⭐⭐⭐ (5/5) ou ⭐⭐⭐⭐☆ (4/5)

**Vulnerabilities Found**: [Lista de CVEs ou issues]

**Action Items**:
- [ ] [Criar issue para adicionar rate limiting em endpoint X]

---

### 7. Auditing Golden Path Compliance

- [ ] **What to Audit**: Todas ações state-changing logadas
- [ ] **Audit Schema**: WHO, WHAT, WHEN, WHERE, METADATA presentes
- [ ] **Storage**: PostgreSQL `audit_events` table
- [ ] **Immutability**: Logs não podem ser deletados
- [ ] **GDPR Compliance**: Right to Access e Right to Erasure implementados

**Score**: ⭐⭐⭐⭐⭐ (5/5) ou ⭐⭐⭐⭐☆ (4/5)

**Gaps Identificados**:
- [Ex: "Ação user.deleted não está sendo logada"]

**Action Items**:
- [ ] [Criar issue para adicionar audit log em user.deleted]

---

### 8. Quality Golden Path Compliance

- [ ] **Test Pyramid**: 70% unit / 20% integration / 10% e2e alcançado
- [ ] **Unit Tests**: Table-driven, mocks corretos
- [ ] **Integration Tests**: Testcontainers usado
- [ ] **Code Coverage**: ≥80% overall, ≥90% critical paths
- [ ] **Linting**: RuboCop configurado, zero offenses
- [ ] **Benchmarks**: Performance tests documentados

**Score**: ⭐⭐⭐⭐⭐ (5/5) ou ⭐⭐⭐⭐☆ (4/5)

**Test Coverage Detail**:
```
Package                    Coverage
internal/domain/user       92%
internal/service/user      85%
internal/infra/http        78%
Overall                    82%
```

**Action Items**:
- [ ] [Aumentar coverage de internal/infra/http para ≥80%]

---

### 9. Development Golden Path Compliance

- [ ] **Git Workflow**: Feature branches, trunk-based
- [ ] **Commit Messages**: Conventional Commits seguido
- [ ] **Pull Requests**: Template usado, reviewers adequados
- [ ] **i18n**: Mensagens user-facing em translation keys
- [ ] **Database Migrations**: Rails migrations, up/down testados

**Score**: ⭐⭐⭐⭐⭐ (5/5) ou ⭐⭐⭐⭐☆ (4/5)

**Gaps Identificados**:
- [Ex: "3 commits não seguiram Conventional Commits"]

**Action Items**:
- [ ] [Setup commit-msg hook para enforçar Conventional Commits]

---

### 10. UX Golden Path Compliance

- [ ] **User-Centric**: Design validado com personas
- [ ] **Simplicity**: Fluxos com ≤5 passos
- [ ] **Consistency**: Biblioteca de componentes usada
- [ ] **Accessibility**: WCAG 2.1 AA compliance verificado
- [ ] **Error Handling**: Mensagens amigáveis, CTAs claros
- [ ] **Empty States**: Implementados onde aplicável

**Score**: ⭐⭐⭐⭐⭐ (5/5) ou ⭐⭐⭐⭐☆ (4/5)

**UX Issues**:
- [Ex: "Empty state em /users não tem CTA claro"]

**Action Items**:
- [ ] [Adicionar CTA "Create User" em empty state]

---

## 🎯 Success Criteria Evaluation

### 11. Functional Success

- [ ] Todos os acceptance criteria passaram
- [ ] Demo completado com stakeholders
- [ ] Feedback positivo de usuários (ex: Sarah, Maria)

**User Feedback**:
> "Quote do feedback de Maria: 'Dashboard está muito intuitivo, consegui encontrar usuários em segundos!'"

---

### 12. Non-Functional Success

| Requirement | Target | Actual | Met? |
|-------------|--------|--------|------|
| Performance (p95) | <200ms | [X]ms | ✅/❌ |
| Uptime | 99.9% | [X]% | ✅/❌ |
| Scalability | 10k users | Tested [X] users | ✅/❌ |
| Security | 0 critical vulns | [X] vulns | ✅/❌ |

---

## 🐛 Issues & Technical Debt

### 13. Known Issues

Lista de bugs conhecidos não resolvidos:

| Issue ID | Severity | Description | Plan |
|----------|----------|-------------|------|
| #123 | P2 | [Descrição] | [Fix em Sprint N+1] |
| #124 | P3 | [Descrição] | [Backlog] |

---

### 14. Technical Debt

Lista de technical debt introduzido:

| Item | Impact | Effort to Fix | Priority |
|------|--------|---------------|----------|
| [Ex: Lack of caching in List Users] | Medium | 1 day | P2 |
| [Ex: Hardcoded timeout values] | Low | 0.5 day | P3 |

**Total Debt**: [X] days of work

**Action Items**:
- [ ] Criar issues para top 3 debt items
- [ ] Schedule debt paydown em Sprint N+2

---

## 📚 Lessons Learned

### 15. What Went Well? ✅

List 3-5 coisas que funcionaram bem:

1. **[Ex: Test-driven development]**: Escrever testes primeiro reduziu bugs em 50%
2. **[Ex: Daily standups]**: Identificamos bloqueadores cedo
3. **[...]**

---

### 16. What Could Be Improved? ⚠️

List 3-5 áreas de melhoria:

1. **[Ex: Code review time]**: PRs ficaram em review por média de 2 dias, meta é 1 dia
   - **Action**: Adicionar rotation schedule para reviewers
2. **[Ex: Integration test coverage]**: Apenas 15%, meta era 20%
   - **Action**: Dedicar 1 dia em próximo sprint para integration tests
3. **[...]**

---

### 17. What Should We Stop Doing? ❌

List práticas a descontinuar:

1. **[Ex: Last-minute documentation]**: Documentar durante desenvolvimento, não depois
2. **[...]**

---

### 18. What Should We Start Doing? ✨

List práticas novas a adotar:

1. **[Ex: Pair programming para features complexas]**: Reduz bugs e aumenta knowledge sharing
2. **[Ex: Weekly architecture review]**: Garantir aderência ao Clean Architecture
3. **[...]**

---

## 🔄 Retrospective Action Items

### 19. Immediate Actions (Sprint N+1)

- [ ] [Action 1, owner, deadline]
- [ ] [Action 2, owner, deadline]
- [ ] [Action 3, owner, deadline]

---

### 20. Long-term Improvements

- [ ] [Improvement 1, owner, deadline]
- [ ] [Improvement 2, owner, deadline]

---

## 📊 Epic Summary

### Overall Score: [X]/100

**Breakdown**:
- Functional Delivery: [X]/20
- Code Quality: [X]/20
- Security: [X]/15
- Performance: [X]/15
- Golden Path Compliance: [X]/20
- Documentation: [X]/10

**Epic Status**: ✅ Success / ⚠️ Partial Success / ❌ Failure

**Recommendation**: [Release / Hold / Rollback]

---

## 📝 Next Epic Preparation

### 21. Blockers for Next Epic

- [ ] [Blocker 1: Ex: Need to upgrade Keycloak to v27]
- [ ] [Blocker 2: Ex: Frontend dev not yet allocated]

---

### 22. Dependencies Created

List dependencies que outros epics terão:

- **Epic E[X+1]** depends on: [Ex: User CRUD API endpoints]
- **Epic E[X+2]** depends on: [Ex: RBAC middleware]

---

## ✅ Sign-off

| Role | Name | Approved | Date | Signature |
|------|------|----------|------|-----------|
| **Tech Lead** | [Nome] | ✅ / ❌ | [YYYY-MM-DD] | |
| **Product Owner** | [Nome] | ✅ / ❌ | [YYYY-MM-DD] | |
| **Security Team** | [Nome] | ✅ / ❌ | [YYYY-MM-DD] | |

---

## 📤 Final Actions

- [ ] Atualizar `documentation/product-planning/initiative-progress.md` com status "Completo"
- [ ] Update burndown chart
- [ ] Schedule Epic celebration! 🎉
- [ ] Arquivo este review em `documentation/product-planning/epics/E[X]-review.md`

---

**Epic Review Completed! 🎊**

---

## Appendix: Commands Reference

```bash
# Test Coverage
bundle exec rspec
open coverage/index.html

# Coverage JSON (for CI)
cat coverage/.last_run.json

# Lint
bundle exec rubocop

# Security Scan
bundle exec brakeman -q
bundle audit check

# Code Quality
bundle exec rubocop --format json > rubocop.json
bundle exec flay app/ lib/

# Benchmark (if using benchmark-ips gem)
ruby benchmarks/user_queries_benchmark.rb

# Load Test
./loadtest -users 10000 -concurrency 100 -token $TOKEN
```
