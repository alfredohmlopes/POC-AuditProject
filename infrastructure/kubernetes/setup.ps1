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

# Functions
function Install-Redpanda {
    Write-Host "🐼 Installing Redpanda Cluster (Helm)..."
    helm repo add redpanda https://charts.redpanda.com
    helm repo update
    helm upgrade --install redpanda redpanda/redpanda `
        --namespace redpanda `
        --create-namespace `
        --values redpanda/values.yaml `
        --wait
    
    Write-Host "Redpanda installation completed." -ForegroundColor Green
}

function Install-ClickHouse {
    Write-Host "📊 Installing ClickHouse via Operator..."
    helm repo add clickhouse-operator https://docs.altinity.com/clickhouse-operator/
    helm repo update
    helm upgrade --install clickhouse-operator clickhouse-operator/altinity-clickhouse-operator `
        --namespace clickhouse `
        --create-namespace `
        --values clickhouse/operator-values.yaml `
        --wait

    Write-Host "Deploying ClickHouse Cluster..."
    kubectl apply -k clickhouse/
    
    Write-Host "ClickHouse installation initiated." -ForegroundColor Green
}

function Install-OpenSearch {
    Write-Host "🔍 Installing OpenSearch via Operator..."
    helm repo add opensearch-operator https://opensearch-project.github.io/opensearch-k8s-operator/
    helm repo update
    helm upgrade --install opensearch-operator opensearch-operator/opensearch-operator `
        --namespace opensearch-operator-system `
        --create-namespace `
        --wait

    Write-Host "Deploying OpenSearch Cluster..."
    kubectl create namespace opensearch 2>$null
    
    # Create Admin Secret
    $secretExists = kubectl get secret admin-credentials -n opensearch --ignore-not-found
    if (-not $secretExists) {
        kubectl create secret generic admin-credentials --from-literal=password=changeme_admin123 --from-literal=username=admin -n opensearch
    }

    kubectl apply -k opensearch/
    
    Write-Host "OpenSearch installation initiated." -ForegroundColor Green
}

# --- Main Execution ---

# 4. Install Redpanda
Install-Redpanda

# 5. Install ClickHouse
Install-ClickHouse

# 6. Install OpenSearch
Install-OpenSearch

Write-Host "✅ Infrastructure setup completed successfully!" -ForegroundColor Green
