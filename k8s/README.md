# Kubernetes Manifests for Book Review Platform

This directory contains Kubernetes manifests for deploying the Book Review Platform application.

## Structure

```
k8s/
├── namespace.yaml              # Namespace definition
├── external-secret.yaml        # External Secrets configuration for Azure Key Vault
├── postgres-pvc.yaml           # Persistent storage for PostgreSQL
├── postgres-deployment.yaml    # PostgreSQL database
├── postgres-service.yaml       # PostgreSQL service
├── book-api-deployment.yaml    # Node.js API backend
├── book-api-service.yaml       # API service
├── book-ui-deployment.yaml     # Frontend UI
├── book-ui-service.yaml        # UI service
└── ingress.yaml                # NGINX Ingress for routing
```

## Deployment Methods

### Option 1: ArgoCD (Recommended for GitOps)

The application is configured to be deployed via ArgoCD. Apply the ArgoCD Application manifest from the root of the repository:

```bash
kubectl apply -f argocd-app.yaml
```

ArgoCD will:
- Automatically sync the k8s manifests to your cluster
- Monitor for changes in the Git repository
- Self-heal if cluster state drifts from Git
- Provide a visual UI for deployment status

### Option 2: Manual kubectl apply

For testing or manual deployment:

```bash
# Apply all manifests
kubectl apply -f k8s/

# Or apply in order
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/postgres-pvc.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml
kubectl apply -f k8s/book-api-deployment.yaml
kubectl apply -f k8s/book-api-service.yaml
kubectl apply -f k8s/book-ui-deployment.yaml
kubectl apply -f k8s/book-ui-service.yaml
kubectl apply -f k8s/ingress.yaml
```

## Configuration

### Secrets Management

This application uses **Azure Key Vault + External Secrets Operator** for secure secret management.

**Setup Steps:**

1. Deploy Terraform to create Key Vault and store secrets
2. Update `external-secret.yaml` with your Key Vault name
3. External Secrets Operator will automatically sync secrets to Kubernetes

See [EXTERNAL-SECRETS-SETUP.md](EXTERNAL-SECRETS-SETUP.md) for detailed configuration instructions.

### Container Images

Update the image references in the deployment files with your ACR login server:

```yaml
image: <YOUR_ACR_NAME>.azurecr.io/book-api:latest
```

Or use ArgoCD Image Updater to automatically update images from CI/CD.

### Secrets

**Development**: The `secrets.yaml` file contains placeholder values.

**Production**: Use Azure Key Vault with External Secrets Operator:

1. Store secrets in Azure Key Vault
2. Install External Secrets Operator in your cluster
3. Create ExternalSecret resources to sync secrets from Key Vault

Example:
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: book-review-secrets
  namespace: book-review-platform
spec:
  secretStoreRef:
    name: azure-key-vault
    kind: SecretStore
  target:
    name: book-review-secrets
  data:
  - secretKey: POSTGRES_PASSWORD
    remoteRef:
      key: postgres-password
  - secretKey: JWT_SECRET
    remoteRef:
      key: jwt-secret
```

### Environment Variables

Update values in the deployment files:
- Database name: `DB_NAME`
- Database user: `DB_USER`
- Other environment-specific configurations

## Access the Application

After deployment:

```bash
# Get the LoadBalancer IP
kubectl get ingress -n book-review-platform

# Or use port-forward for local testing
kubectl port-forward -n book-review-platform svc/book-ui 8080:80
```

## Monitoring

```bash
# Check pod status
kubectl get pods -n book-review-platform

# View logs
kubectl logs -n book-review-platform -l app=book-api
kubectl logs -n book-review-platform -l app=book-ui
kubectl logs -n book-review-platform -l app=postgres

# Describe resources
kubectl describe deployment book-api -n book-review-platform
```

## ArgoCD Management

```bash
# Watch sync status
kubectl get application -n argocd book-review-platform -w

# Force sync
kubectl patch application book-review-platform -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'

# Or use ArgoCD CLI
argocd app sync book-review-platform
argocd app get book-review-platform
```
