# ACR Authentication Options for AKS

## Option 1: AKS-ACR Integration (Recommended - No Secrets Needed!)

If your AKS cluster and ACR are in the same subscription, use AKS managed identity integration:

```bash
# Attach ACR to AKS cluster (run this once)
az aks update -n <AKS_CLUSTER_NAME> -g <AKS_RESOURCE_GROUP> --attach-acr containerplatformdevacr

# Verify integration
az aks check-acr -n <AKS_CLUSTER_NAME> -g <AKS_RESOURCE_GROUP> --acr containerplatformdevacr.azurecr.io
```

**This is the recommended approach** - no secrets to manage, AKS kubelet identity is automatically granted AcrPull role.

---

## Option 2: Image Pull Secret (If ACR integration not available)

If you need to use credentials (cross-subscription or other scenarios), create a Kubernetes image pull secret.

### Step 1: Get ACR Credentials

```bash
# Get admin credentials (enable admin user first if not enabled)
az acr update -n containerplatformdevacr --admin-enabled true

# Get credentials
ACR_USERNAME=$(az acr credential show -n containerplatformdevacr --query "username" -o tsv)
ACR_PASSWORD=$(az acr credential show -n containerplatformdevacr --query "passwords[0].value" -o tsv)

echo "Username: $ACR_USERNAME"
echo "Password: $ACR_PASSWORD"
```

### Step 2: Create Image Pull Secret

**Option A: Using kubectl (manual)**

```bash
kubectl create secret docker-registry acr-secret \
  --docker-server=containerplatformdevacr.azurecr.io \
  --docker-username=$ACR_USERNAME \
  --docker-password=$ACR_PASSWORD \
  --docker-email=your-email@example.com \
  --namespace=book-review-platform
```

**Option B: Using YAML manifest** (add to k8s/acr-secret.yaml)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: acr-secret
  namespace: book-review-platform
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <BASE64_ENCODED_DOCKER_CONFIG>
```

To generate the base64 value:
```bash
kubectl create secret docker-registry acr-secret \
  --docker-server=containerplatformdevacr.azurecr.io \
  --docker-username=$ACR_USERNAME \
  --docker-password=$ACR_PASSWORD \
  --docker-email=your-email@example.com \
  --dry-run=client -o jsonpath='{.data.\.dockerconfigjson}'
```

### Step 3: Reference Secret in Deployments

Add `imagePullSecrets` to each deployment spec:

```yaml
spec:
  template:
    spec:
      imagePullSecrets:
      - name: acr-secret
      containers:
      - name: book-api
        image: containerplatformdevacr.azurecr.io/book-api:latest
```

---

## Option 3: Service Principal (For Production with RBAC)

Create a service principal with AcrPull role:

```bash
# Create service principal
ACR_REGISTRY_ID=$(az acr show --name containerplatformdevacr --query id --output tsv)
SP_PASSWORD=$(az ad sp create-for-rbac --name http://acr-pull-sp --scopes $ACR_REGISTRY_ID --role acrpull --query password --output tsv)
SP_APP_ID=$(az ad sp list --display-name http://acr-pull-sp --query "[].appId" --output tsv)

# Create secret
kubectl create secret docker-registry acr-secret \
  --docker-server=containerplatformdevacr.azurecr.io \
  --docker-username=$SP_APP_ID \
  --docker-password=$SP_PASSWORD \
  --namespace=book-review-platform
```

---

## Option 4: Azure Key Vault + External Secrets Operator (Most Secure)

For production environments, store ACR credentials in Azure Key Vault and sync to Kubernetes:

### Step 1: Store credentials in Key Vault

```bash
az keyvault secret set --vault-name <YOUR_KEY_VAULT> --name acr-username --value $ACR_USERNAME
az keyvault secret set --vault-name <YOUR_KEY_VAULT> --name acr-password --value $ACR_PASSWORD
```

### Step 2: Install External Secrets Operator

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace
```

### Step 3: Create ExternalSecret

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: acr-secret
  namespace: book-review-platform
spec:
  secretStoreRef:
    name: azure-key-vault-store
    kind: SecretStore
  target:
    name: acr-secret
    template:
      type: kubernetes.io/dockerconfigjson
      data:
        .dockerconfigjson: |
          {
            "auths": {
              "containerplatformdevacr.azurecr.io": {
                "username": "{{ .username }}",
                "password": "{{ .password }}",
                "auth": "{{ printf "%s:%s" .username .password | b64enc }}"
              }
            }
          }
  data:
  - secretKey: username
    remoteRef:
      key: acr-username
  - secretKey: password
    remoteRef:
      key: acr-password
```

---

## Recommendations

**For Development/Testing:**
- Use **Option 1 (AKS-ACR Integration)** - simplest, no secrets to manage

**For Production:**
- Use **Option 1 (AKS-ACR Integration)** with managed identity if possible
- OR **Option 4 (Azure Key Vault + External Secrets)** for maximum security and rotation capabilities
- Avoid admin credentials in production - use service principals or managed identities

**Current Setup:**
Your manifests are ready to work with Option 1 (no changes needed). If you need image pull secrets, add them to each deployment's `spec.template.spec.imagePullSecrets` section.
