# Turia Trails - Infrastructure Makefile

# Variables
CLUSTER_NAME := turia-local
KUBECONFIG := $(HOME)/.kube/config

# Tools versions
CERT_MANAGER_VERSION := v1.13.3

.PHONY: all setup clean deploy verify

all: setup deploy verify

# 1. Provision Cluster & Dependencies
setup:
	@echo "🚀 Provisioning Kind cluster..."
	kind create cluster --name $(CLUSTER_NAME) --config kind-cluster.yaml || true
	
	@echo "📦 Installing Cert-Manager (Helm)..."
	helm repo add jetstack https://charts.jetstack.io
	helm repo update
	helm upgrade --install cert-manager jetstack/cert-manager \
		--namespace cert-manager \
		--create-namespace \
		--version $(CERT_MANAGER_VERSION) \
		--set installCRDs=true \
		--wait

# 2. Deploy Infrastructure Manifests
deploy:
	@echo "🏗️ Applying Kubernetes Manifests (Kustomize)..."
	kubectl apply -k .

# 3. Verify Installation
verify:
	@echo "🔍 Verifying Workloads..."
	kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx --timeout=90s
	kubectl rollout status deployment/metrics-server -n kube-system --timeout=90s
	@echo "✅ Infrastructure Ready!"

# Clean everything
clean:
	@echo "🧹 Cleaning up..."
	kind delete cluster --name $(CLUSTER_NAME)
