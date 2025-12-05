# Turia Trails: MVP Definition

> **"Simplicidade é a sofisticação máxima."**  
> — Leonardo da Vinci

---

## 1. MVP Vision

### 1.1 Objetivo

Entregar uma **plataforma funcional de auditoria de identidade** que permita aos times de Segurança, Compliance e Operações:

- ✅ **Capturar** eventos de auditoria de produtos integrados
- ✅ **Visualizar** trilhas de atividade em uma interface unificada
- ✅ **Investigar** incidentes com busca e filtros
- ✅ **Alertar** sobre atividades suspeitas em tempo real
- ✅ **Exportar** dados para auditorias e investigações

### 1.2 Proposta de Valor (MVP)

> "Saber **quem** fez **o quê**, **quando** e **onde** em todos os produtos — em segundos, não dias."

---

## 2. Critérios de Sucesso

| Critério | Target MVP |
|----------|------------|
| Produtos integrados ao piloto | 3 produtos |
| Tempo para investigar um incidente | < 5 minutos (vs. dias hoje) |
| Eventos disponíveis para consulta | últimos 90 dias |
| Usuários ativos na plataforma | 20+ (Security, Compliance, Ops) |
| Cobertura de ações críticas | 100% das ações de identidade |

---

## 3. Scope Definition

### 3.1 ✅ IN Scope (MVP)

#### Captura de Eventos
- Ingestão de eventos via API padronizada
- SDK para integração simplificada
- Suporte a eventos síncronos e em lote (batch)
- Schema flexível para diferentes tipos de ação

#### Visualização & Investigação
- Timeline de atividades (cronológico)
- Busca por texto livre
- Filtros por: ação, ator, recurso, período, resultado
- Visualização detalhada de cada evento
- Drill-down no contexto (antes/depois de alterações)

#### Alertas
- 5 regras de alerta pré-configuradas
- Notificações via Email e Slack
- Configuração de limiares básicos
- Dashboard de alertas ativos

#### Exportação
- Export para CSV
- Filtros aplicáveis na exportação
- Download direto da interface

#### Administração
- Gestão de chaves de API
- Controle de acesso básico (Admin, Viewer)
- Login via SSO (ID Magalu)

### 3.2 ❌ OUT of Scope (Post-MVP)

| Feature | Razão do Corte | Fase Futura |
|---------|----------------|-------------|
| Multi-tenancy | Complexidade de isolamento | v2.0 |
| Detecção de anomalias (ML) | Requer volume de dados históricos | v3.0 |
| Integração com SIEM | Enterprise feature | v2.0 |
| Reports de compliance automáticos | SOC2/ISO | v2.0 |
| Automação GDPR (SAR) | Compliance avançado | v2.0 |
| Retenção tiered (hot/warm/cold) | Otimização de custo | v1.5 |
| GraphQL API | Nice-to-have | v1.5 |
| Dashboard analytics avançado | Gráficos, tendências | v1.5 |
| Risk scoring por usuário | UEBA | v3.0 |
| Geolocalização de eventos | Enriquecimento | v1.5 |
| Correlação de eventos | Investigação avançada | v2.0 |

---

## 4. Personas & User Stories

### 4.1 Personas Primárias

| Persona | Papel | Necessidade Principal |
|---------|-------|----------------------|
| **Ana (Security Analyst)** | Analista de Segurança | Investigar incidentes rapidamente |
| **Carlos (Compliance Officer)** | Compliance | Gerar evidências para auditorias |
| **Marina (Platform Engineer)** | Engenheira | Integrar produtos facilmente |

### 4.2 User Stories (MVP)

#### Epic: Captura de Eventos

| ID | Story | Prioridade |
|----|-------|------------|
| **US-01** | Como **Marina**, quero uma API simples para enviar eventos de auditoria, para que eu possa integrar meu produto em poucas horas. | P0 |
| **US-02** | Como **Marina**, quero um SDK que capture contexto automaticamente (IP, user agent), para não precisar coletar manualmente. | P0 |
| **US-03** | Como **Marina**, quero enviar eventos em lote, para otimizar a performance da minha aplicação. | P1 |
| **US-04** | Como **Marina**, quero que o SDK não bloqueie minha aplicação se a API estiver lenta, para não impactar meus usuários. | P0 |

#### Epic: Visualização & Investigação

| ID | Story | Prioridade |
|----|-------|------------|
| **US-10** | Como **Ana**, quero ver uma timeline de eventos recentes, para entender a atividade geral do sistema. | P0 |
| **US-11** | Como **Ana**, quero buscar eventos por email de usuário, para investigar ações de uma pessoa específica. | P0 |
| **US-12** | Como **Ana**, quero filtrar eventos por tipo de ação (ex: login, alteração de role), para focar na investigação. | P0 |
| **US-13** | Como **Ana**, quero ver os detalhes completos de um evento, incluindo o que mudou (before/after), para entender o impacto. | P0 |
| **US-14** | Como **Ana**, quero filtrar por período de tempo, para analisar eventos em um intervalo específico. | P0 |
| **US-15** | Como **Ana**, quero ver eventos que falharam, para identificar tentativas suspeitas. | P1 |

#### Epic: Alertas

| ID | Story | Prioridade |
|----|-------|------------|
| **US-20** | Como **Ana**, quero ser alertada quando houver múltiplas tentativas de login falhadas, para detectar ataques de força bruta. | P0 |
| **US-21** | Como **Ana**, quero ser notificada quando um usuário receber permissões administrativas, para validar se foi autorizado. | P0 |
| **US-22** | Como **Ana**, quero receber alertas no Slack, para reagir rapidamente sem precisar abrir o dashboard. | P1 |
| **US-23** | Como **Ana**, quero ver um histórico dos alertas disparados, para revisar incidentes passados. | P1 |

#### Epic: Exportação & Compliance

| ID | Story | Prioridade |
|----|-------|------------|
| **US-30** | Como **Carlos**, quero exportar eventos filtrados para CSV, para anexar em relatórios de auditoria. | P0 |
| **US-31** | Como **Carlos**, quero ver todos os eventos de um usuário específico, para responder a solicitações de investigação. | P0 |
| **US-32** | Como **Carlos**, quero acessar eventos dos últimos 90 dias, para atender requisitos mínimos de compliance. | P0 |

#### Epic: Administração

| ID | Story | Prioridade |
|----|-------|------------|
| **US-40** | Como **Marina**, quero gerar uma API key para meu produto, para autenticar chamadas à API. | P0 |
| **US-41** | Como **Admin**, quero revogar API keys comprometidas, para manter a segurança. | P0 |
| **US-42** | Como **Admin**, quero controlar quem pode acessar o dashboard (Admin vs Viewer), para limitar ações sensíveis. | P1 |
| **US-43** | Como **Usuário**, quero fazer login via SSO (ID Magalu), para não precisar de senha separada. | P0 |

---

## 5. Evento de Auditoria (Formato Simplificado)

### 5.1 Campos Obrigatórios

| Campo | Descrição | Exemplo |
|-------|-----------|---------|
| **actor** | Quem realizou a ação | `{ id, type, email }` |
| **action** | O que foi feito | `user.created`, `role.assigned` |
| **resource** | Sobre o que a ação foi realizada | `{ type, id }` |
| **timestamp** | Quando aconteceu | `2024-01-15T10:30:45Z` |
| **success** | Se a ação foi bem-sucedida | `true` ou `false` |

### 5.2 Campos Opcionais (Recomendados)

| Campo | Descrição | Exemplo |
|-------|-----------|---------|
| **context.ip_address** | IP do cliente | `192.168.1.100` |
| **context.user_agent** | Browser/cliente usado | `Mozilla/5.0...` |
| **changes.before** | Estado anterior | `{ role: "viewer" }` |
| **changes.after** | Estado posterior | `{ role: "admin" }` |
| **error_message** | Mensagem de erro (se falhou) | `Invalid credentials` |
| **metadata** | Dados customizados | `{ ticket_id: "JIRA-123" }` |

### 5.3 Tipos de Ação Padrão (MVP)

| Categoria | Ações |
|-----------|-------|
| **Autenticação** | `auth.login`, `auth.logout`, `auth.failed`, `auth.mfa_enrolled` |
| **Usuários** | `user.created`, `user.updated`, `user.deleted`, `user.invited` |
| **Permissões** | `role.assigned`, `role.removed`, `permission.granted`, `permission.revoked` |
| **Sessões** | `session.created`, `session.terminated`, `session.expired` |
| **Configurações** | `config.updated`, `setting.changed` |
| **Dados** | `data.exported`, `data.accessed` |

---

## 6. Regras de Alerta Pré-Configuradas

### 6.1 Alertas de Segurança (MVP)

| # | Nome | Condição | Severidade |
|---|------|----------|------------|
| 1 | **Brute Force Detection** | > 5 logins falhados em 5 min (mesmo ator) | 🔴 Crítico |
| 2 | **Admin Role Grant** | Qualquer evento `role.assigned` com role = admin | 🟡 Médio |
| 3 | **Mass Deletion** | > 5 eventos de delete em 5 min (mesmo ator) | 🔴 Crítico |
| 4 | **Off-Hours Admin Action** | Ação admin entre 00:00 - 06:00 (fuso local) | 🟡 Médio |
| 5 | **New Location Login** | Login de país diferente do habitual | 🟡 Médio |

### 6.2 Canais de Notificação

| Canal | Casos de Uso |
|-------|--------------|
| **Email** | Todos os alertas, resumos diários |
| **Slack** | Alertas críticos, time de segurança |

---

## 7. Interface do Usuário

### 7.1 Telas do MVP

| Tela | Funcionalidades |
|------|-----------------|
| **Login** | SSO via ID Magalu |
| **Event List** | Timeline, busca, filtros, paginação |
| **Event Detail** | Detalhes completos, changes before/after |
| **Alerts** | Lista de alertas ativos e histórico |
| **Settings** | API Keys, notificações, perfil |

### 7.2 Wireframe: Event List

```
┌─────────────────────────────────────────────────────────────────────────┐
│  🔍 Turia Trails                         [Alertas 2] [Ana Silva ▼]     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │ Buscar: [email, ação, recurso...                              🔍]  ││
│  └─────────────────────────────────────────────────────────────────────┘│
│                                                                          │
│  Filtros: [Ação: Todas ▼] [Resultado: Todos ▼] [Período: 7 dias ▼]     │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │                                                                      ││
│  │  ✓ 10:30  user.created      admin@magalu.com  → User: joao@...     ││
│  │  ✓ 10:28  role.assigned     admin@magalu.com  → User: maria@...    ││
│  │  ✓ 10:25  auth.login        maria@magalu.com  → Session            ││
│  │  ✗ 10:22  auth.login        atacante@gmail    → Session (Falhou)   ││
│  │  ✗ 10:21  auth.login        atacante@gmail    → Session (Falhou)   ││
│  │  ✓ 10:15  user.updated      joao@magalu.com   → User: joao@...     ││
│  │                                                                      ││
│  └─────────────────────────────────────────────────────────────────────┘│
│                                                                          │
│  Mostrando 1-50 de 12.345 eventos           [◀ Anterior] [Próximo ▶]   │
│                                                                          │
│  [📥 Exportar CSV]                                                       │
└─────────────────────────────────────────────────────────────────────────┘
```

### 7.3 Wireframe: Event Detail

```
┌─────────────────────────────────────────────────────────────────────────┐
│  ← Voltar                                              Event: abc-123   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │  ✓ role.assigned                                                     ││
│  │  15 Jan 2024, 10:28:45                                              ││
│  └─────────────────────────────────────────────────────────────────────┘│
│                                                                          │
│  QUEM (Actor)                                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │  👤 admin@magalu.com (Admin)                                        ││
│  │  IP: 192.168.1.100 • Chrome/Windows                                 ││
│  └─────────────────────────────────────────────────────────────────────┘│
│                                                                          │
│  O QUÊ (Ação)                                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │  Ação: role.assigned                                                ││
│  │  Recurso: User • maria@magalu.com                                   ││
│  └─────────────────────────────────────────────────────────────────────┘│
│                                                                          │
│  MUDANÇAS                                                                │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │  role:   viewer  →  admin                                           ││
│  └─────────────────────────────────────────────────────────────────────┘│
│                                                                          │
│  METADADOS                                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │  Serviço: user-management-api                                       ││
│  │  Ambiente: production                                                ││
│  │  Request ID: req-xyz-789                                            ││
│  └─────────────────────────────────────────────────────────────────────┘│
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 8. Jornadas de Usuário

### 8.1 Jornada: Investigação de Incidente

```
┌─────────────────────────────────────────────────────────────────────────┐
│  CENÁRIO: Ana recebe alerta de múltiplos logins falhados               │
└─────────────────────────────────────────────────────────────────────────┘

     TRIGGER                INVESTIGAÇÃO                    AÇÃO
        │                        │                            │
        ▼                        ▼                            ▼
  ┌──────────┐            ┌──────────────┐            ┌──────────────┐
  │ 🔔 Alerta │           │ 🔍 Buscar por │           │ ✅ Bloquear   │
  │ no Slack │──────────▸ │ email do     │──────────▸│ conta se     │
  │          │            │ atacante     │            │ necessário   │
  └──────────┘            └──────────────┘            └──────────────┘
                                 │
                                 ▼
                          ┌──────────────┐
                          │ 📊 Ver padrão │
                          │ de tentativas │
                          │ (IPs, horários)│
                          └──────────────┘
                                 │
                                 ▼
                          ┌──────────────┐
                          │ 📥 Exportar   │
                          │ evidências   │
                          │ para CSV     │
                          └──────────────┘

  TEMPO TOTAL: < 5 minutos (vs. dias anteriormente)
```

### 8.2 Jornada: Auditoria de Compliance

```
┌─────────────────────────────────────────────────────────────────────────┐
│  CENÁRIO: Carlos precisa evidências de acessos para auditor externo    │
└─────────────────────────────────────────────────────────────────────────┘

     SOLICITAÇÃO              COLETA                    ENTREGA
         │                      │                          │
         ▼                      ▼                          ▼
   ┌──────────┐          ┌──────────────┐          ┌──────────────┐
   │ 📧 Auditor │         │ 🔍 Filtrar    │         │ 📥 Exportar   │
   │ solicita  │────────▸│ por período  │────────▸│ CSV com      │
   │ evidências│         │ e tipo       │         │ evidências   │
   └──────────┘          └──────────────┘          └──────────────┘
                                │
                                ▼
                         ┌──────────────┐
                         │ 👁️ Revisar    │
                         │ eventos      │
                         │ relevantes   │
                         └──────────────┘

  TEMPO TOTAL: < 30 minutos (vs. semanas anteriormente)
```

### 8.3 Jornada: Integração de Produto

```
┌─────────────────────────────────────────────────────────────────────────┐
│  CENÁRIO: Marina quer integrar seu produto com Turia Trails            │
└─────────────────────────────────────────────────────────────────────────┘

     SETUP                  INTEGRAÇÃO                 VALIDAÇÃO
       │                        │                          │
       ▼                        ▼                          ▼
  ┌──────────┐           ┌──────────────┐          ┌──────────────┐
  │ 🔑 Gerar  │          │ 📦 Instalar   │         │ 🔍 Ver eventos │
  │ API key  │─────────▸ │ SDK e        │────────▸│ no dashboard │
  │          │           │ configurar   │          │              │
  └──────────┘           └──────────────┘          └──────────────┘
                                │
                                ▼
                         ┌──────────────┐
                         │ 📝 Adicionar  │
                         │ eventos nas  │
                         │ ações chave  │
                         └──────────────┘

  TEMPO TOTAL: < 1 dia (vs. semanas anteriormente)
```

---

## 9. Métricas de Sucesso MVP

### 9.1 Métricas de Adoção

| Métrica | Target (3 meses) |
|---------|------------------|
| Produtos integrados | 3+ |
| Eventos ingeridos/dia | 100K+ |
| Usuários ativos (MAU) | 20+ |
| Investigações realizadas | 50+ |
| Exports gerados | 100+ |

### 9.2 Métricas de Experiência

| Métrica | Target |
|---------|--------|
| Tempo de integração | < 1 dia |
| Tempo para primeira busca | < 30 segundos |
| NPS dos usuários | > 30 |
| Taxa de conclusão de investigação | > 90% |

### 9.3 Métricas Operacionais

| Métrica | Target |
|---------|--------|
| Disponibilidade | 99.5% |
| Latência de ingestão | < 5 segundos |
| Tempo de busca | < 3 segundos |
| Taxa de falha de ingestão | < 0.1% |

---

## 10. Produtos Piloto Sugeridos

### 10.1 Critérios de Seleção

- ✅ Alto volume de ações de identidade
- ✅ Necessidade clara de auditoria
- ✅ Time engajado para integração
- ✅ Criticidade de compliance

### 10.2 Candidatos Prioritários

| Produto | Justificativa | Ações Principais |
|---------|---------------|------------------|
| **ID Magalu** | Core de identidade, alto volume | Login, registro, MFA |
| **RBAC Service** | Gestão de permissões, compliance crítico | Role assign, permission grant |
| **User Management** | CRUD de usuários, visibilidade obrigatória | User CRUD, invite |

---

## 11. Riscos do MVP

| Risco | Impacto | Probabilidade | Mitigação |
|-------|---------|---------------|-----------|
| Baixa adoção pelos times | Alto | Médio | Suporte hands-on, demos |
| Volume maior que esperado | Médio | Médio | Design escalável desde início |
| Schema insuficiente | Médio | Alto | JSONB para flexibilidade |
| Alertas com muito ruído | Médio | Médio | Começar conservador, ajustar |
| Complexidade de busca | Baixo | Médio | Índices adequados, cache |

---

## 12. Roadmap Pós-MVP

### 12.1 Visão de Releases

```
    MVP          v1.5           v2.0           v3.0
     │            │              │              │
     ▼            ▼              ▼              ▼
┌─────────┐  ┌─────────┐   ┌─────────┐   ┌─────────┐
│ Core    │  │ Scale   │   │ Enterpr │   │ AI &    │
│ Platform│  │ + DX    │   │ + Compl │   │ Product │
└─────────┘  └─────────┘   └─────────┘   └─────────┘
     │            │              │              │
     │            │              │              │
• Ingest API  • +2 SDKs     • Multi-tenant  • Anomaly ML
• Dashboard   • GraphQL     • SIEM export   • Risk score
• 5 Alerts    • Geo enrich  • GDPR automat  • AaaS launch
• CSV Export  • Tiered stor • Cust reports  • Marketplace
• 3 produtos  • 10 produtos • 30 produtos   • Ext customers
```

### 12.2 Features por Release

| Release | Timeline | Principais Features |
|---------|----------|---------------------|
| **v1.5** | +2 meses | SDKs adicionais, GraphQL, storage tiers |
| **v2.0** | +4 meses | Multi-tenancy, SIEM, GDPR, custom reports |
| **v3.0** | +6 meses | ML anomalies, UEBA, launch comercial |

---

## 13. Definição de Pronto (DoD)

### 13.1 Checklist MVP Launch

#### Funcionalidade
- [ ] Ingestão de eventos funcionando
- [ ] Dashboard com busca e filtros
- [ ] 5 regras de alerta ativas
- [ ] Export CSV operacional
- [ ] SSO funcionando

#### Qualidade
- [ ] Zero bugs críticos
- [ ] Performance dentro dos targets
- [ ] Segurança revisada
- [ ] Documentação completa

#### Adoção
- [ ] 3 produtos integrados
- [ ] 20+ usuários com acesso
- [ ] Treinamento realizado
- [ ] Suporte definido

---

## 14. Próximos Passos

1. **Validar escopo** com stakeholders (Security, Compliance, Platform)
2. **Confirmar produtos piloto** e agendar kick-offs
3. **Definir squad** e alocar recursos
4. **Kick-off técnico** com arquitetura e planning

---

**Status**: Draft  
**Versão**: 1.0  
**Última atualização**: 2024-12-05
