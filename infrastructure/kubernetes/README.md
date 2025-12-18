# Turia Trails - Kubernetes Infrastructure

> **Story**: E1.S1 - Kubernetes Cluster Setup  
> **Status**: ✅ Complete

---

## Overview

Este diretório contém os manifests Kubernetes para o Turia Trails, organizados como **Infrastructure as Code (IaC)** usando Kustomize.

## Cloud vs. Local Strategy

Para garantir que o provisionamento seja tranquilo na Cloud, usamos o padrão **Base/Overlays**:

1.  **Base (`base/`)**: Definições comuns a todos os ambientes (Deployments, Services, ConfigMaps).
2.  **Overlays (`overlays/`)**: Customizações específicas por ambiente via Kustomize patches.
    *   *Local (Kind)*: Usa StorageClass local, NodePorts/LoadBalancer simulado.
    *   *Production (AWS/MGC)*: Usa StorageClass gerenciado (EBS/GP3), ALB Ingress, ExternalDNS.

Atualmente estamos trabalhando no ambiente **Base** + configurações compatíveis com local.

---

## 🏥 Verificar Saúde dos Pods

### Ver todos os pods (todas as namespaces)
```powershell
kubectl get pods -A
```

### Ver pods por namespace específico
```powershell
# APISIX e serviços da aplicação
kubectl get pods -n apisix

# Monitoramento (Prometheus, Grafana)
kubectl get pods -n monitoring

# PostgreSQL
kubectl get pods -n postgresql

# Redis
kubectl get pods -n redis

# ClickHouse
kubectl get pods -n clickhouse

# OpenSearch
kubectl get pods -n opensearch

# Redpanda (Kafka)
kubectl get pods -n redpanda

# Vector (ingestion)
kubectl get pods -n vector
```

### Status de um pod específico
```powershell
# Ver detalhes de um pod (substitua <nome-do-pod> e <namespace>)
kubectl describe pod <nome-do-pod> -n <namespace>

# Exemplo:
kubectl describe pod query-api-79dbbf6495-wsknh -n apisix
```

### Ver logs de um pod
```powershell
# Últimas 50 linhas de log
kubectl logs <nome-do-pod> -n <namespace> --tail=50

# Seguir logs em tempo real (Ctrl+C para sair)
kubectl logs <nome-do-pod> -n <namespace> -f

# Exemplo:
kubectl logs query-api-79dbbf6495-wsknh -n apisix --tail=50
```

### Reiniciar um pod com problemas
```powershell
# Deletar o pod (o Kubernetes cria um novo automaticamente)
kubectl delete pod <nome-do-pod> -n <namespace>

# Exemplo:
kubectl delete pod query-api-79dbbf6495-wsknh -n apisix
```

---

## 🔌 Acessar Serviços (Port-Forward)

Port-forward cria um "túnel" para acessar serviços do Kubernetes no seu computador.

### Serviços da Aplicação
```powershell
# Query API (consulta de eventos)
kubectl port-forward svc/query-api 8091:8081 -n apisix
# Acessar: http://localhost:8091/health

# Event Gateway (ingestão de eventos)
kubectl port-forward svc/event-gateway 8090:8080 -n apisix
# Acessar: http://localhost:8090/health

# APISIX Gateway (API Gateway)
kubectl port-forward svc/apisix-gateway 9080:80 -n apisix
# Acessar: http://localhost:9080

# APISIX Admin API
kubectl port-forward svc/apisix-admin 9180:9180 -n apisix
# Acessar: http://localhost:9180
```

### Monitoramento
```powershell
# Grafana (dashboards)
kubectl port-forward svc/kube-prometheus-stack-grafana 3001:80 -n monitoring
# Acessar: http://localhost:3001
# Usuário: admin
# Senha: changeme_grafana123

# Prometheus (métricas)
kubectl port-forward svc/prometheus-kube-prometheus-stack-prometheus 9090:9090 -n monitoring
# Acessar: http://localhost:9090
```

### Banco de Dados e Filas
```powershell
# Redpanda Console (Kafka UI)
kubectl port-forward svc/redpanda-console 8080:8080 -n redpanda
# Acessar: http://localhost:8080

# ClickHouse (SQL Analytics)
kubectl port-forward svc/clickhouse-audit 8123:8123 -n clickhouse
# Acessar: http://localhost:8123

# OpenSearch Dashboard
kubectl port-forward svc/audit-search-dashboards 5601:5601 -n opensearch
# Acessar: http://localhost:5601
```

---

## 📊 Comandos Úteis

### Ver uso de recursos (CPU/Memória)
```powershell
# Por pod
kubectl top pods -A

# Por node
kubectl top nodes
```

### Ver eventos recentes (erros)
```powershell
# Todos os eventos
kubectl get events -A --sort-by='.lastTimestamp' | Select-Object -Last 20

# Eventos de uma namespace específica
kubectl get events -n apisix --sort-by='.lastTimestamp'
```

### Verificar se o cluster está funcionando
```powershell
# Status dos nodes
kubectl get nodes

# Status de todos os deployments
kubectl get deployments -A
```

---

## 🆘 Solucionando Problemas Comuns

### Pod em "CrashLoopBackOff"
```powershell
# Ver logs do pod com problema
kubectl logs <nome-do-pod> -n <namespace> --previous

# Reiniciar o deployment inteiro
kubectl rollout restart deployment/<nome-deployment> -n <namespace>
```

### Pod em "Pending" (esperando)
```powershell
# Ver motivo do pending
kubectl describe pod <nome-do-pod> -n <namespace> | Select-String "Events:" -Context 0,10
```

### Pod em "ImagePullBackOff"
```powershell
# A imagem Docker não existe ou não pode ser baixada
# Verificar nome da imagem no describe
kubectl describe pod <nome-do-pod> -n <namespace> | Select-String "Image:"
```

---

## Automation

Para facilitar, usamos scripts de automação:

- **Linux/Mac**: `Makefile`
- **Windows**: `setup.ps1`

```bash
# Windows
.\setup.ps1

# Linux/Mac
make setup
make deploy
```

## Directory Structure

```
infrastructure/kubernetes/
├── Makefile                    # Automação de provisionamento
├── kind-cluster.yaml           # Spec do cluster local
├── kustomization.yaml          # Root application
├── base/                       # Resources comuns
│   ├── namespace.yaml
│   ├── rbac/
│   ├── storage-classes/
│   └── network-policies/
├── ingress/
├── cert-manager/
└── monitoring/
```

## Quick Start

```bash
cd infrastructure/kubernetes
make all
```

---

**Last Updated**: 2025-12-17

