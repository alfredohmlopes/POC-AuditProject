# Epic 6: Alerting

> **"Prevention is better than cure."**

---

## 1. Epic Overview

| Field | Value |
|-------|-------|
| **Epic ID** | E6 |
| **Epic Name** | Alerting |
| **Priority** | P0 - Critical Path |
| **Timeline** | Weeks 13-14 |
| **Owner** | Backend Team |
| **Dependencies** | E3 (Storage), E5 (Dashboard) |

## 2. Objective

Implementar sistema de alertas em tempo real para detectar atividades suspeitas e notificar via Email e Slack.

## 3. Success Criteria

- [ ] 5 regras de alerta pré-configuradas funcionando
- [ ] Notificações via Email funcionando
- [ ] Notificações via Slack funcionando
- [ ] Dashboard de alertas na UI
- [ ] Latência de alerta < 5 minutos após evento

## 4. User Stories

### E6.S1 - Alert Engine Setup

| Field | Value |
|-------|-------|
| **Story ID** | E6.S1 |
| **Title** | Criar Alert Engine |
| **Priority** | P0 |
| **Points** | 8 |

**User Story**:
Como **Engenheiro Backend**, quero um serviço de alertas, para processar regras e disparar notificações.

**Acceptance Criteria**:
- [ ] Serviço de alerta deployado
- [ ] Consumer do Redpanda para eventos real-time
- [ ] Engine de regras configurável
- [ ] State management para janelas temporais (Redis)
- [ ] Métricas de alertas disparados

---

### E6.S2 - Alert Rule Schema

| Field | Value |
|-------|-------|
| **Story ID** | E6.S2 |
| **Title** | Definir Schema de Regras |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Admin**, quero regras de alerta configuráveis, para definir condições de detecção.

**Acceptance Criteria**:
- [ ] Tabela `alert_rules` no PostgreSQL
- [ ] Campos: name, description, condition, threshold, window, severity, channels
- [ ] Suporte a condições: count, threshold, pattern
- [ ] Suporte a group_by (por actor, por IP)
- [ ] Enabled/disabled flag

**Schema**:
```sql
CREATE TABLE alert_rules (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    severity VARCHAR(20) NOT NULL, -- critical, warning, info
    condition JSONB NOT NULL,
    /* Example condition:
    {
      "type": "threshold",
      "query": { "action": "auth.login", "success": false },
      "threshold": 5,
      "window_minutes": 5,
      "group_by": ["actor_email"]
    }
    */
    channels TEXT[] NOT NULL, -- ['email', 'slack']
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### E6.S3 - Brute Force Alert

| Field | Value |
|-------|-------|
| **Story ID** | E6.S3 |
| **Title** | Alerta Brute Force |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Ana (Security Analyst)**, quero ser alertada sobre tentativas de brute force, para tomar ação imediata.

**Acceptance Criteria**:
- [ ] Regra: > 5 logins falhados em 5 minutos (mesmo actor)
- [ ] Severidade: Critical
- [ ] Notificação inclui: actor_email, count, IPs
- [ ] Dedupe: não alertar novamente dentro da janela

---

### E6.S4 - Admin Role Grant Alert

| Field | Value |
|-------|-------|
| **Story ID** | E6.S4 |
| **Title** | Alerta Role Admin Concedida |
| **Priority** | P0 |
| **Points** | 3 |

**User Story**:
Como **Ana (Security Analyst)**, quero ser notificada quando alguém receber role admin, para validar se é legítimo.

**Acceptance Criteria**:
- [ ] Regra: qualquer evento `role.assigned` com role=admin
- [ ] Severidade: Medium
- [ ] Notificação inclui: who granted, who received, when

---

### E6.S5 - Mass Deletion Alert

| Field | Value |
|-------|-------|
| **Story ID** | E6.S5 |
| **Title** | Alerta Mass Deletion |
| **Priority** | P0 |
| **Points** | 3 |

**User Story**:
Como **Ana (Security Analyst)**, quero ser alertada sobre deleções em massa, para detectar atividade maliciosa.

**Acceptance Criteria**:
- [ ] Regra: > 5 eventos delete em 5 minutos (mesmo actor)
- [ ] Severidade: Critical
- [ ] Aplicável a: user.deleted, role.removed, etc.

---

### E6.S6 - Off-Hours Alert

| Field | Value |
|-------|-------|
| **Story ID** | E6.S6 |
| **Title** | Alerta Atividade Fora do Horário |
| **Priority** | P1 |
| **Points** | 3 |

**User Story**:
Como **Ana (Security Analyst)**, quero ser alertada sobre ações admin fora do horário comercial, para investigar.

**Acceptance Criteria**:
- [ ] Regra: ação admin entre 00:00-06:00 (horário local)
- [ ] Severidade: Medium
- [ ] Configurável por tenant (timezone)

---

### E6.S7 - Email Notifications

| Field | Value |
|-------|-------|
| **Story ID** | E6.S7 |
| **Title** | Notificações via Email |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Ana (Security Analyst)**, quero receber alertas por email, para ser notificada mesmo offline.

**Acceptance Criteria**:
- [ ] Integração com SMTP ou SendGrid
- [ ] Template HTML para alertas
- [ ] Subject com severidade e resumo
- [ ] Link para dashboard com detalhes
- [ ] Rate limiting (max 10 emails/hora por regra)

---

### E6.S8 - Slack Notifications

| Field | Value |
|-------|-------|
| **Story ID** | E6.S8 |
| **Title** | Notificações via Slack |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Ana (Security Analyst)**, quero receber alertas no Slack, para reagir rapidamente com meu time.

**Acceptance Criteria**:
- [ ] Integração via Webhook
- [ ] Formatação rica (blocks, attachments)
- [ ] Cores por severidade (red, yellow, blue)
- [ ] Link para dashboard
- [ ] Configurável por canal

---

### E6.S9 - Alert History

| Field | Value |
|-------|-------|
| **Story ID** | E6.S9 |
| **Title** | Histórico de Alertas |
| **Priority** | P1 |
| **Points** | 5 |

**User Story**:
Como **Ana (Security Analyst)**, quero ver histórico de alertas, para revisar incidentes passados.

**Acceptance Criteria**:
- [ ] Tabela `alert_events` no PostgreSQL
- [ ] Lista de alertas no dashboard
- [ ] Filtro por severidade, status, data
- [ ] Detalhe do alerta com eventos relacionados
- [ ] Marcar como "reviewed" / "false positive"

---

### E6.S10 - Alert Dashboard Widget

| Field | Value |
|-------|-------|
| **Story ID** | E6.S10 |
| **Title** | Widget de Alertas no Dashboard |
| **Priority** | P1 |
| **Points** | 3 |

**User Story**:
Como **Usuário do Dashboard**, quero ver alertas recentes, para estar ciente de problemas.

**Acceptance Criteria**:
- [ ] Badge com count de alertas não lidos
- [ ] Dropdown com últimos 5 alertas
- [ ] Link para página completa de alertas
- [ ] Indicador visual por severidade

---

## 5. Dependencies

| Dependency | Type | Description |
|------------|------|-------------|
| E3.S1 | Internal | Consumer de eventos |
| E5.S3 | Internal | Dashboard para exibição |
| Slack | External | Webhook configuration |
| SMTP | External | Email server |

## 6. Pre-configured Alert Rules (MVP)

| # | Name | Condition | Severity |
|---|------|-----------|----------|
| 1 | Brute Force | > 5 failed logins in 5 min | Critical |
| 2 | Admin Role Grant | role.assigned with admin | Medium |
| 3 | Mass Deletion | > 5 deletes in 5 min | Critical |
| 4 | Off-Hours Admin | Admin action 00:00-06:00 | Medium |
| 5 | New Location | Login from new country | Medium |

## 7. Definition of Done

- [ ] 5 regras de alerta funcionando
- [ ] Email e Slack notificando
- [ ] Histórico de alertas visível
- [ ] Latência < 5 min
- [ ] Documentação de configuração

---

**Status**: Draft  
**Created**: 2024-12-05
