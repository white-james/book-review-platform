# Kubernetes Manifests for Book Review Platform

This directory contains Kubernetes manifests for deploying the Book Review Platform application.

## Deployment Methods

### Option 1: ArgoCD (Recommended for GitOps)

The application is configured to be deployed via ArgoCD. Apply the ArgoCD Application manifest from the root of the repository:

```bash
kubectl apply -f application.yml
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
kubectl apply -f kubernetes-manifests/

# Or apply in order
kubectl apply -f kubernetes-manifests/namespace.yml
kubectl apply -f kubernetes-manifests/secrets.yml
kubectl apply -f kubernetes-manifests/postgres-pvc.yml
kubectl apply -f kubernetes-manifests/postgres-deployment.yml
kubectl apply -f kubernetes-manifests/postgres-service.yml
kubectl apply -f kubernetes-manifests/book-api-deployment.yml
kubectl apply -f kubernetes-manifests/book-api-service.yml
kubectl apply -f kubernetes-manifests/book-ui-deployment.yml
kubectl apply -f kubernetes-manifests/book-ui-service.yml
kubectl apply -f kubernetes-manifests/ingress.yml
```

## Testing The Book Review Platform locally using KIND

```bash
# Port forward the UI and API
kubectl port-forward svc/book-api 3000:3000 -n book-review-platform
kubectl port-forward svc/book-ui 8080:80 -n book-review-platform
```

## Troubleshooting commands

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