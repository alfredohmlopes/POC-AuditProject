$ErrorActionPreference = "Stop"

Write-Host "🚀 Provisioning Infrastructure..."

# 1. Cert-Manager
Write-Host "📦 Installing Cert-Manager..."
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager `
    --namespace cert-manager `
    --create-namespace `
    --version v1.13.3 `
    --set installCRDs=true `
    --wait

# 2. Apply Manifests (StorageClasses, Namespace, etc)
Write-Host "🏗️ Applying Kubernetes Manifests..."
# Apply base infrastructure first so StorageClasses exist
kubectl apply -k .

# 3. Redpanda Cluster
Write-Host "🐼 Installing Redpanda Cluster (Helm)..."
helm repo add redpanda https://charts.redpanda.com
helm repo update
helm upgrade --install redpanda redpanda/redpanda `
    --namespace redpanda `
    --create-namespace `
    --values redpanda/values.yaml `
    --wait

Write-Host "✅ Setup Complete!"
