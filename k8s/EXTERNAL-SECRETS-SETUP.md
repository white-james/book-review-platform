# External Secrets Setup Guide

This guide explains how to configure External Secrets Operator to sync secrets from Azure Key Vault to Kubernetes.

## Prerequisites

1. **External Secrets Operator installed** in the AKS cluster (should be in kubernetes-platform repo)
2. **AKS cluster deployed** with kubelet managed identity
3. **Key Vault created** via Terraform in this repo

## Setup Steps

### Step 1: Get Required Information

After deploying the Terraform in this repo, get the following values:

```bash
cd terraform

# Get Key Vault name
KV_NAME=$(terraform output -raw key_vault_name)
echo "Key Vault Name: $KV_NAME"

# Get Key Vault URI
KV_URI=$(terraform output -raw key_vault_uri)
echo "Key Vault URI: $KV_URI"
```

### Step 2: Update External Secret Configuration

Update [`k8s/external-secret.yaml`](k8s/external-secret.yaml) with your Key Vault URI:

```bash
# Replace the placeholder with your actual Key Vault name
sed -i "s/\${KEY_VAULT_NAME}/$KV_NAME/g" k8s/external-secret.yaml
```

Or manually edit the file and replace:
```yaml
vaultUrl: "https://${KEY_VAULT_NAME}.vault.azure.net/"
```

With:
```yaml
vaultUrl: "https://YOUR-ACTUAL-KV-NAME.vault.azure.net/"
```

### Step 3: Verify AKS Has Access to Key Vault

The Terraform in this repo grants the AKS kubelet identity access to read secrets. Verify with:

```bash
# Get the kubelet identity object ID (from kubernetes-platform repo)
AKS_IDENTITY=$(az aks show -n <AKS_NAME> -g <PLATFORM_RG> --query identityProfile.kubeletidentity.objectId -o tsv)

# Check role assignments on Key Vault
az role assignment list --scope /subscriptions/<SUB_ID>/resourceGroups/<YOUR_RG>/providers/Microsoft.KeyVault/vaults/$KV_NAME --assignee $AKS_IDENTITY
```

You should see the "Key Vault Secrets User" role assigned.

### Step 4: Deploy Application via ArgoCD

```bash
# Apply the ArgoCD Application manifest
kubectl apply -f argocd-app.yaml

# Watch the deployment
kubectl get application -n argocd book-review-platform -w
```

### Step 5: Verify Secret Sync

Check that External Secrets Operator created the Kubernetes secret:

```bash
# Check ExternalSecret status
kubectl get externalsecret -n book-review-platform
kubectl describe externalsecret book-review-secrets -n book-review-platform

# Check if the Kubernetes secret was created
kubectl get secret book-review-secrets -n book-review-platform

# Verify secret data (should show keys but not values)
kubectl describe secret book-review-secrets -n book-review-platform
```

### Step 6: Verify Pods Can Access Secrets

```bash
# Check pod status
kubectl get pods -n book-review-platform

# Check pod environment variables (secrets should be injected)
kubectl exec -n book-review-platform deployment/book-api -- env | grep -E 'DB_PASSWORD|JWT_SECRET'
```

## Terraform Variable Setup

You need to provide the AKS kubelet identity object ID to Terraform:

```bash
# Get the object ID from the kubernetes-platform repo
cd ../kubernetes-platform/terraform
AKS_IDENTITY=$(terraform output -raw aks_kubelet_identity_object_id)

# Set it in your book-review-platform tfvars
cd ../../book-review-platform/terraform
cat >> terraform.tfvars <<EOF
aks_kubelet_identity_object_id = "$AKS_IDENTITY"
EOF
```

Or add it to your Azure DevOps pipeline variables.

## Troubleshooting

### ExternalSecret shows "SecretSyncedError"

Check the External Secrets Operator logs:
```bash
kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets
```

Common issues:
- **AKS doesn't have Key Vault Secrets User role**: Re-run Terraform in this repo
- **Key Vault URL is incorrect**: Verify the `vaultUrl` in external-secret.yaml
- **Workload Identity not configured**: Ensure External Secrets Operator is configured for Workload Identity

### Secret not appearing in Kubernetes

```bash
# Check SecretStore status
kubectl get secretstore -n book-review-platform
kubectl describe secretstore azure-keyvault -n book-review-platform

# Check ExternalSecret events
kubectl get events -n book-review-platform --sort-by='.lastTimestamp' | grep ExternalSecret
```

### Pods can't read secrets

```bash
# Check if secret exists
kubectl get secret book-review-secrets -n book-review-platform -o yaml

# Check pod events
kubectl describe pod <POD_NAME> -n book-review-platform
```

## Security Best Practices

1. **Never commit the actual Key Vault name to Git** - use templating or provide it at deployment time
2. **Use Workload Identity** instead of service principal credentials
3. **Rotate secrets regularly** in Azure Key Vault (External Secrets will auto-sync)
4. **Monitor secret access** via Key Vault audit logs
5. **Use separate Key Vaults** per environment (dev, staging, prod)

## Updating Secrets

To update secrets after initial deployment:

```bash
# Update in Key Vault (via Azure Portal or CLI)
az keyvault secret set --vault-name $KV_NAME --name db-password --value "new-password"

# External Secrets Operator will automatically sync within refreshInterval (default: 1h)
# Or force immediate sync:
kubectl annotate externalsecret book-review-secrets -n book-review-platform force-sync="$(date +%s)"

# Restart pods to pick up new secrets
kubectl rollout restart deployment/book-api -n book-review-platform
kubectl rollout restart deployment/book-ui -n book-review-platform
kubectl rollout restart deployment/postgres -n book-review-platform
```
