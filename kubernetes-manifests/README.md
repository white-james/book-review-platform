# Kubernetes Manifests for Book Review Platform

This directory contains Kubernetes manifests for deploying the Book Review Platform application.

## Deployment

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