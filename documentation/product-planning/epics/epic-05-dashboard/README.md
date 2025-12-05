# Epic 5: Dashboard

> **"Data is only useful if you can see it."**

---

## 1. Epic Overview

| Field | Value |
|-------|-------|
| **Epic ID** | E5 |
| **Epic Name** | Dashboard |
| **Priority** | P0 - Critical Path |
| **Timeline** | Weeks 9-12 |
| **Owner** | Frontend Team |
| **Dependencies** | E4 (Query API) |

## 2. Objective

Desenvolver o dashboard web para visualização e investigação de eventos de auditoria, com busca, filtros, detalhes de eventos e exportação.

## 3. Success Criteria

- [ ] Login via SSO (ID Magalu) funcionando
- [ ] Lista de eventos com busca e filtros
- [ ] Visualização de detalhes do evento
- [ ] Exportação CSV da interface
- [ ] Performance < 3s para carregamento inicial
- [ ] Design responsivo (desktop first)

## 4. User Stories

### E5.S1 - Project Setup

| Field | Value |
|-------|-------|
| **Story ID** | E5.S1 |
| **Title** | Setup Projeto Frontend |
| **Priority** | P0 |
| **Points** | 3 |

**User Story**:
Como **Desenvolvedor Frontend**, quero um projeto configurado com React + Vite, para desenvolver o dashboard rapidamente.

**Acceptance Criteria**:
- [ ] Projeto React + Vite + TypeScript criado
- [ ] Design system básico (Tailwind ou Chakra)
- [ ] Router configurado (React Router)
- [ ] State management (Zustand ou React Query)
- [ ] Build e deploy configurados
- [ ] ESLint + Prettier

---

### E5.S2 - Authentication (SSO)

| Field | Value |
|-------|-------|
| **Story ID** | E5.S2 |
| **Title** | Login via SSO |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Usuário**, quero fazer login via ID Magalu, para acessar o dashboard sem criar nova conta.

**Acceptance Criteria**:
- [ ] Redirect para ID Magalu para login
- [ ] Callback URL configurada
- [ ] Token JWT armazenado de forma segura
- [ ] Refresh token flow
- [ ] Logout funcional
- [ ] Protected routes

---

### E5.S3 - Event List Page

| Field | Value |
|-------|-------|
| **Story ID** | E5.S3 |
| **Title** | Página de Lista de Eventos |
| **Priority** | P0 |
| **Points** | 8 |

**User Story**:
Como **Ana (Security Analyst)**, quero ver uma lista de eventos recentes, para monitorar a atividade do sistema.

**Acceptance Criteria**:
- [ ] Tabela de eventos com colunas: timestamp, action, actor, resource, status
- [ ] Ordenação por timestamp (mais recente primeiro)
- [ ] Indicador visual para sucesso (✓) e falha (✗)
- [ ] Paginação infinita ou cursor-based
- [ ] Loading state e error handling
- [ ] Refresh automático (opcional) ou manual

**Wireframe Reference**: Ver MVP doc seção 7.2

---

### E5.S4 - Search Bar

| Field | Value |
|-------|-------|
| **Story ID** | E5.S4 |
| **Title** | Barra de Busca |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Ana (Security Analyst)**, quero buscar eventos por texto, para encontrar rapidamente o que procuro.

**Acceptance Criteria**:
- [ ] Input de busca no topo da página
- [ ] Busca ao pressionar Enter ou clicar no ícone
- [ ] Debounce de 300ms para busca enquanto digita (opcional)
- [ ] Clear button para limpar busca
- [ ] Resultados refletem busca full-text
- [ ] Placeholder com exemplos: "email, ação, recurso..."

---

### E5.S5 - Filter Panel

| Field | Value |
|-------|-------|
| **Story ID** | E5.S5 |
| **Title** | Painel de Filtros |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Ana (Security Analyst)**, quero filtrar eventos por critérios específicos, para focar na investigação.

**Acceptance Criteria**:
- [ ] Dropdown para filtro de Action (multi-select)
- [ ] Dropdown para filtro de Resultado (Sucesso, Falha, Todos)
- [ ] Date range picker para período
- [ ] Presets: Últimas 24h, 7 dias, 30 dias, Custom
- [ ] Botão "Limpar Filtros"
- [ ] URL reflete filtros aplicados (deep linking)

---

### E5.S6 - Event Detail Page

| Field | Value |
|-------|-------|
| **Story ID** | E5.S6 |
| **Title** | Página de Detalhes do Evento |
| **Priority** | P0 |
| **Points** | 5 |

**User Story**:
Como **Ana (Security Analyst)**, quero ver todos os detalhes de um evento, para entender completamente o contexto.

**Acceptance Criteria**:
- [ ] Navegação ao clicar em um evento na lista
- [ ] Exibição de todos os campos do evento
- [ ] Seção WHO (Actor) com avatar, email, type, IP
- [ ] Seção WHAT (Action) com action name, resource
- [ ] Seção CHANGES com diff visual (before/after)
- [ ] Seção METADATA com dados extras
- [ ] Botão "Voltar para Lista"
- [ ] Copiar Event ID

**Wireframe Reference**: Ver MVP doc seção 7.3

---

### E5.S7 - Export CSV

| Field | Value |
|-------|-------|
| **Story ID** | E5.S7 |
| **Title** | Exportar para CSV |
| **Priority** | P0 |
| **Points** | 3 |

**User Story**:
Como **Carlos (Compliance Officer)**, quero exportar eventos filtrados para CSV, para anexar em relatórios.

**Acceptance Criteria**:
- [ ] Botão "Exportar CSV" na lista de eventos
- [ ] Aplica filtros atuais na exportação
- [ ] Download inicia automaticamente
- [ ] Feedback de progresso para exports grandes
- [ ] Limite exibido (max 100K eventos)

---

### E5.S8 - Settings Page

| Field | Value |
|-------|-------|
| **Story ID** | E5.S8 |
| **Title** | Página de Configurações |
| **Priority** | P1 |
| **Points** | 5 |

**User Story**:
Como **Marina (Platform Engineer)**, quero gerenciar minhas API Keys, para integrar produtos com Turia Trails.

**Acceptance Criteria**:
- [ ] Lista de API Keys do usuário/tenant
- [ ] Criar nova API Key (com nome)
- [ ] Exibir API Key apenas uma vez (no create)
- [ ] Revogar API Key existente
- [ ] Mostrar última utilização de cada key
- [ ] Copiar API Key para clipboard

---

### E5.S9 - Responsive Design

| Field | Value |
|-------|-------|
| **Story ID** | E5.S9 |
| **Title** | Design Responsivo |
| **Priority** | P1 |
| **Points** | 3 |

**User Story**:
Como **Usuário**, quero acessar o dashboard em diferentes dispositivos, para verificar eventos quando necessário.

**Acceptance Criteria**:
- [ ] Desktop (1280px+): Layout completo
- [ ] Tablet (768px-1279px): Layout adaptado
- [ ] Mobile (< 768px): Layout simplificado
- [ ] Navegação mobile-friendly
- [ ] Tabela scrollável horizontalmente em mobile

---

### E5.S10 - Error Handling & Loading States

| Field | Value |
|-------|-------|
| **Story ID** | E5.S10 |
| **Title** | Estados de Loading e Erro |
| **Priority** | P0 |
| **Points** | 3 |

**User Story**:
Como **Usuário**, quero feedback visual claro, para saber quando dados estão carregando ou houve erro.

**Acceptance Criteria**:
- [ ] Skeleton loaders durante carregamento
- [ ] Spinner para ações assíncronas
- [ ] Mensagens de erro amigáveis
- [ ] Botão "Tentar Novamente" em erros
- [ ] Toast notifications para ações (export, copy, etc.)

---

## 5. Dependencies

| Dependency | Type | Description |
|------------|------|-------------|
| E4.S2 | Internal | Query API endpoints |
| ID Magalu | External | SSO authentication |

## 6. Definition of Done

- [ ] Todas as telas funcionando
- [ ] Testes E2E principais (login, busca, filtros)
- [ ] Performance < 3s first load
- [ ] Acessibilidade básica (WCAG AA)
- [ ] Cross-browser (Chrome, Firefox, Safari)
- [ ] Deploy em staging

---

**Status**: Draft  
**Created**: 2024-12-05
