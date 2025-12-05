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

## Automation (`Makefile`)

Para evitar comandos manuais, todo o processo de setup está codificado no `Makefile`:

```bash
# Provisiona cluster, instala deps (Helm) e aplica manifests
make all

# Apenas atualiza manifests
make deploy

# Destroi tudo
make clean
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

**Last Updated**: 2024-12-05
