# Golden Path Documentation

> **"The Golden Path is the opinionated and supported path to build your application."**

This directory contains the engineering standards and best practices for the CIAM Platform. Follow these guidelines to ensure consistency, quality, security, and maintainability across the codebase.

---

## 📚 Documentation Index


### 2. [Development Golden Path](./development.md) 💻
**Development workflow and coding standards**

- Git workflow (trunk-based development)
- Commit message conventions (Conventional Commits)
- Pull request process and code review
- Ruby on Rails coding standards and style guide
- Internationalization (i18n) requirements
- Database migrations
- CI/CD pipeline standards

**When to read**: Before starting any development work

---

### 3. [Security Golden Path](./security.md) 🔒
**Security best practices and requirements**

- Zero Trust Architecture principles
- Authentication & Authorization (JWT, RBAC)
- Input validation and SQL injection prevention
- Password security and cryptography standards
- Network security (TLS, CORS, rate limiting)
- Secrets management
- Compliance requirements (GDPR, SOC 2)
- Security checklists

**When to read**: Before implementing any auth, data access, or API endpoint

---

### 4. [Auditing & Compliance Golden Path](./auditing.md) 📋
**Audit logging and compliance standards**

- Audit logging principles (the 5 W's)
- Audit log schema and storage
- GDPR compliance (Right to Access, Right to Erasure)
- SOC 2 and ISO 27001 requirements
- Security event monitoring and alerts
- Audit queries and compliance reports

**When to read**: Before implementing state-changing operations

---

### 5. [Quality Golden Path](./quality.md) ✅
**Testing and code quality standards**

- Test Pyramid (70% unit, 20% integration, 10% E2E)
- Unit testing practices (table-driven tests, mocks)
- Integration testing with testcontainers
- Code coverage requirements (≥80%)
- Linting and static analysis
- Performance testing and benchmarking
- Code review checklist

**When to read**: Before merging any code (Definition of Done)

---

### 6. [UX/UI Golden Path](./ux.md) 🎨
**User experience and interface design standards**

- UX principles (User-centric, Simplicity, Consistency)
- Developer Experience (DX) best practices
- Component library and design system
- Accessibility requirements (WCAG 2.1 AA)
- Responsive design patterns
- Error handling and empty states
- Documentation UX

**When to read**: Before designing or implementing any UI component

---

## 🎯 Quick Reference

### For Backend Engineers:
1. Read: [Architecture](./architecture.md) → [Development](./development.md) → [Security](./security.md)
2. Review: [Quality](./quality.md) before every PR

### For Frontend Engineers:
1. Read: [UX](./ux.md) → [Security](./security.md) (authentication/forms)
2. Review: [Quality](./quality.md) testing standards

### For Security Reviews:
1. Check: [Security](./security.md) checklist (Section 10)
2. Verify: [Auditing](./auditing.md) for state-changing actions

### For Compliance Audits:
1. Review: [Auditing](./auditing.md) (GDPR, SOC 2, ISO 27001)
2. Check: [Security](./security.md) Section 9 (Compliance)

---

## 📊 Key Metrics & Standards

| Metric | Standard | Link |
|--------|----------|------|
| **Test Coverage** | ≥ 80% overall | [Quality](./quality.md#11-test-pyramid) |
| **Code Complexity** | < 15 cyclomatic | [Quality](./quality.md#33-static-analysis) |
| **API Response Time** | p95 < 200ms | [Architecture](./architecture.md) |
| **Accessibility** | WCAG 2.1 AA | [UX](./ux.md#3-accessibility-wcag-21-aa) |
| **Security Audit** | All PRs checked | [Security](./security.md#10-security-checklist) |
| **Audit Log Retention** | Minimum 1 year | [Auditing](./auditing.md#22-immutability) |

---

## ✅ Definition of Done

Before marking any task as complete, verify:

### Code Quality
- [ ] Follows [Architecture Golden Path](./architecture.md) (Clean Architecture, SOLID)
- [ ] Passes `bundle exec rubocop` with zero offenses
- [ ] Code coverage ≥ 80% (see [Quality](./quality.md))
- [ ] No hardcoded values (use constants or config)

### Security
- [ ] All inputs validated (see [Security](./security.md#3-input-validation--sanitization))
- [ ] Authentication and authorization implemented
- [ ] No secrets committed, loaded from environment
- [ ] SQL injection prevention (parameterized queries)

### Testing
- [ ] Unit tests written (see [Quality](./quality.md#12-unit-tests))
- [ ] Integration tests for critical paths
- [ ] Edge cases and error scenarios tested

### Auditing
- [ ] State-changing actions logged (see [Auditing](./auditing.md#11-what-to-audit))
- [ ] Audit log includes WHO, WHAT, WHEN, WHERE

### Documentation
- [ ] Code comments for complex logic
- [ ] API documentation updated (OpenAPI)
- [ ] README updated if needed
- [ ] i18n keys exist for user-facing messages

### Review
- [ ] Self-reviewed in GitHub UI
- [ ] Peer-reviewed and approved
- [ ] CI/CD pipeline passes
- [ ] Security review (if auth/crypto changes)

---

## 🚀 Getting Started

### New Team Members:
1. Read all Golden Path docs (2-3 hours)
2. Review example PRs that follow these standards
3. Set up linting and pre-commit hooks
4. Ask questions in team chat

### Before Your First PR:
1. Review [Development Golden Path](./development.md) (Git workflow, PR process)
2. Check [Quality Golden Path](./quality.md) (testing requirements)
3. Run through Definition of Done checklist above

---

## 🔄 Continuous Improvement

These Golden Path documents are living documents. They should be:

- **Reviewed** quarterly (are standards still relevant?)
- **Updated** when we learn better practices
- **Enforced** via code review and CI/CD
- **Discussed** in retrospectives (what's working? what isn't?)

**Propose Changes**: Create a PR to update Golden Path docs, discuss with team

---

## 📖 Philosophy

> **"Security, Resilience, Quality, Scalability, and Performance are our north star."**

These Golden Path documents encode our values:

1. **Security**: Zero Trust, defense in depth, compliance-ready
2. **Quality**: Test-driven, code review, continuous improvement
3. **Scalability**: Clean Architecture, stateless services, horizontal scaling
4. **Performance**: Caching, connection pooling, optimized queries
5. **Developer Experience**: Clear docs, great tooling, fast feedback loops

---

**Last Updated**: 2025-11-28  
**Version**: 1.0  
**Status**: Active

---

**Remember**: "The Golden Path is not a cage—it's a well-lit trail through the forest. You can step off the path when needed, but know where you are and why."
