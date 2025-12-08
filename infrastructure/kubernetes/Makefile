# Turia Trails - Infrastructure Makefile

# Variables
CLUSTER_NAME := turia-local
KUBECONFIG := $(HOME)/.kube/config

# Tools versions
CERT_MANAGER_VERSION := v1.13.3

.PHONY: all setup clean deploy verify

# Clean everything
clean:
	@echo "🧹 Cleaning up..."
	kind delete cluster --name $(CLUSTER_NAME)

install-opensearch:
	@echo "Installing OpenSearch Operator..."
	helm repo add opensearch-operator https://opensearch-project.github.io/opensearch-k8s-operator/
	helm repo update
	helm upgrade --install opensearch-operator opensearch-operator/opensearch-operator \
		--namespace opensearch-operator-system \
		--create-namespace \
		--wait
	@echo "Deploying OpenSearch Cluster..."
	kubectl create namespace opensearch || true
	# Create Basic Auth Secret manually for simplicity if not using a generator
	# Username: admin, Password: changeme_admin123
	kubectl create secret generic admin-credentials --from-literal=password=changeme_admin123 --from-literal=username=admin -n opensearch --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -k opensearch/

install-postgres:
	@echo "Installing PostgreSQL..."
	kubectl create namespace postgresql --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -k postgresql/
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo update
	helm upgrade --install postgresql bitnami/postgresql \
		--namespace postgresql \
		-f postgresql/values.yaml \
		--wait
	@echo "Installing PgBouncer..."
	helm upgrade --install postgresql-pgbouncer bitnami/pgbouncer \
		--namespace postgresql \
		-f postgresql/pgbouncer-values.yaml \
		--set postgresql.password=changeme_postgres123 \
		--wait
