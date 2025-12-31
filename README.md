# Book Review Platform

A full-stack web application for book reviews built with Node.js, PostgreSQL, and served with Nginx. This project demonstrates modern cloud-native development practices with GitOps deployment using ArgoCD.

## 🚀 Tech Stack

- **Backend:** Node.js + Express.js (REST API)
- **Frontend:** HTML5 + Bootstrap + Vanilla JavaScript
- **Database:** PostgreSQL
- **Web Server:** Nginx (for serving static files)
- **Authentication:** JWT (JSON Web Tokens)
- **Containerization:** Docker & Docker Compose
- **Infrastructure as Code:** Terraform
- **Cloud Platform:** Microsoft Azure (ACI & AKS)
- **GitOps:** ArgoCD
- **CI/CD:** Azure DevOps Pipelines
- **Secret Management:** Azure Key Vault + External Secrets Operator

## 📋 Features

- User registration and authentication
- Add new books to the database
- Browse and search books
- Write and view book reviews
- Rate books (1-5 stars)
- View personal review history
- Responsive web design

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend API   │    │   Database      │
│   (Nginx)       │───▶│   (Node.js)     │───▶│   (PostgreSQL)  │
│   Port: 80      │    │   Port: 3000    │    │   Port: 5432    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🌐 Deployment Options

This project supports three deployment methods:

| Environment | Technology | Use Case |
|-------------|------------|----------|
| **Local** | Docker Compose | Development & Testing |
| **Azure Container Instances** | Terraform + ACI | Simple cloud deployment |
| **Azure Kubernetes Service** | GitOps + ArgoCD | Production-grade deployment |

### Deployment Architecture Comparison

```
Local (Docker Compose)
├── docker-compose.yml
└── All containers on localhost

Azure Container Instances (ACI)
├── Terraform manages container groups
├── Azure Container Registry for images
└── Simple, serverless containers

Azure Kubernetes Service (AKS)
├── Platform infrastructure (separate repo)
│   ├── AKS cluster
│   ├── Azure Container Registry
│   ├── NGINX Ingress Controller
│   ├── cert-manager
│   └── External Secrets Operator
└── Application deployment (this repo)
    ├── Kubernetes manifests in k8s/
    ├── ArgoCD manages deployments
    └── Azure Key Vault for secrets
```

---

## 🐳 Option 1: Local Docker Deployment

### Prerequisites

- Docker Desktop installed
- Docker Compose installed

### Quick Start

1. Clone this repository
2. Navigate to the project directory
3. Run with the PowerShell script:

```powershell
# Build and start all services
.\start.ps1 start

# Or use Docker Compose directly
docker-compose up --build -d
```

4. Access the application:
   - **Frontend:** http://localhost:8080
   - **API:** http://localhost:3000

### PowerShell Script Commands

```powershell
.\start.ps1 start    # Start all services
.\start.ps1 stop     # Stop all services
.\start.ps1 logs     # View logs
.\start.ps1 restart  # Restart services
.\start.ps1 clean    # Remove containers and volumes
.\start.ps1 status   # Show service status
.\start.ps1 help     # View all commands
```

---

## ☁️ Option 2: Azure Container Instances (ACI)

Deploy to Azure Container Instances for a simple, serverless container experience.

### Prerequisites

- Azure subscription
- Azure CLI installed
- Terraform installed
- Azure DevOps (for CI/CD)

### Infrastructure Components

- **Resource Group** - Logical container for resources
- **Azure Container Registry (ACR)** - Private Docker registry
- **Azure Key Vault** - Secure secret storage
- **Container Group** - Runs all three containers (UI, API, PostgreSQL)

### Deployment

```powershell
cd terraform

# Initialize Terraform
terraform init

# Plan deployment (ACI)
terraform plan

# Apply
terraform apply
```

---

## ☸️ Option 3: Azure Kubernetes Service (AKS)

Deploy to AKS using GitOps with ArgoCD for a production-grade, scalable Kubernetes environment.

### Prerequisites

- Access to the kubernetes-platform cluster (managed by platform team)
- kubectl installed
- Azure CLI installed
- Access to Azure Key Vault for secrets

### Architecture

```
┌────────────────────────────────────────────────────────────────┐
│               kubernetes-platform Repo (Platform Team)          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  - AKS Cluster                                           │  │
│  │  - Azure Container Registry (ACR)                        │  │
│  │  - NGINX Ingress Controller (Helm)                       │  │
│  │  - cert-manager (Helm)                                   │  │
│  │  - ArgoCD (Helm)                                         │  │
│  │  - External Secrets Operator (Helm)                      │  │
│  │  - Network Infrastructure (VNet, NSG)                    │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
                            │
                            │ ArgoCD watches
                            │
                            ▼
┌────────────────────────────────────────────────────────────────┐
│            book-review-platform Repo (App Team)                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  k8s/                                                    │  │
│  │  ├── namespace.yaml                                      │  │
│  │  ├── postgres-*.yaml                                     │  │
│  │  ├── book-api-*.yaml                                     │  │
│  │  ├── book-ui-*.yaml                                      │  │
│  │  ├── ingress.yaml                                        │  │
│  │  ├── secret-store.yaml                                   │  │
│  │  └── external-secret.yaml                                │  │
│  │                                                          │  │
│  │  terraform/                                              │  │
│  │  ├── keyvault.tf         (App's Key Vault)              │  │
│  │  └── aci.tf              (DB init job)                  │  │
│  │                                                          │  │
│  │  argocd-app.yaml         (ArgoCD Application)           │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
                            │
                            │ Syncs secrets from
                            │
                            ▼
                    ┌──────────────────┐
                    │  Azure Key Vault │
                    │  (App-specific)  │
                    └──────────────────┘
```

### Kubernetes Architecture

```
                    ┌─────────────────────────────────────────┐
                    │     Azure Kubernetes Service (AKS)      │
                    │                                          │
Internet ──────────▶│  ┌─────────────────────────────────┐    │
                    │  │   NGINX Ingress Controller       │    │
                    │  │      (LoadBalancer IP)           │    │
                    │  └───────────────┬─────────────────┘    │
                    │                  │                       │
                    │    ┌─────────────┴─────────────┐        │
                    │    │                           │        │
                    │    ▼                           ▼        │
                    │  /api/*                       /*        │
                    │  ┌─────────┐              ┌─────────┐   │
                    │  │ book-api│              │ book-ui │   │
                    │  │ (x2)    │              │ (x2)    │   │
                    │  └────┬────┘              └─────────┘   │
                    │       │                                  │
                    │       ▼                                  │
                    │  ┌─────────┐    ┌─────────────────┐     │
                    │  │postgres │───▶│ Azure Managed   │     │
                    │  │ (x1)    │    │ Disk (10Gi)     │     │
                    │  └─────────┘    └─────────────────┘     │
                    │                                          │
                    │  ┌──────────────────────────────────┐   │
                    │  │  External Secrets Operator       │   │
                    │  │  (syncs from Azure Key Vault)    │   │
                    │  └──────────────────────────────────┘   │
                    └─────────────────────────────────────────┘
```

### GitOps Workflow

1. **Developer pushes code** to book-review-platform repo
2. **Azure DevOps pipeline** builds Docker images and pushes to ACR
3. **Developer updates** image tags in `k8s/*.yaml` manifests
4. **ArgoCD detects** Git changes automatically
5. **ArgoCD syncs** manifests to AKS cluster
6. **External Secrets Operator** pulls secrets from Azure Key Vault
7. **Application is deployed** with zero manual kubectl commands

### Deployment

```bash
# 1. Ensure platform infrastructure exists (done by platform team)
# 2. Set up your Key Vault secrets (via Azure Portal or Terraform)

cd terraform
terraform init
terraform apply  # Creates Key Vault and stores secrets

# 3. Deploy ArgoCD Application
kubectl apply -f argocd-app.yaml

# 4. Watch ArgoCD sync your application
kubectl get application -n argocd book-review-platform -w

# 5. ArgoCD will automatically deploy all resources from k8s/ directory
```

### Accessing the Application

```bash
# Get the Ingress IP
kubectl get ingress -n book-review-platform

# Access the app at http://<INGRESS_IP>
```

### Useful kubectl Commands

```bash
# View all resources
kubectl get all -n book-review-platform

# View ArgoCD application status
kubectl get application -n argocd book-review-platform

# View pod logs
kubectl logs -l app=book-api -n book-review-platform

# Check External Secrets sync status
kubectl get externalsecrets -n book-review-platform
kubectl describe externalsecret book-review-secrets -n book-review-platform

# View synced secrets
kubectl get secret book-review-secrets -n book-review-platform

# Force ArgoCD sync (if auto-sync is disabled)
kubectl patch application book-review-platform -n argocd \
  --type merge -p '{"operation":{"sync":{}}}'
```

### ArgoCD Web UI

Access the ArgoCD dashboard to view deployment status:

```bash
# Port-forward to ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Visit https://localhost:8080
```

---

## 📁 Project Structure

```
book-review-platform/
├── .azuredevops/             # Azure DevOps Pipelines
│   ├── docker_build_and_push.yml
│   ├── terraform_deploy.yml
│   └── variables.yml
├── book-api/                 # Node.js Backend
│   ├── routes/
│   ├── middleware/
│   ├── server.js
│   ├── package.json
│   └── Dockerfile
├── book-ui/                  # Frontend
│   ├── css/
│   ├── js/
│   │   └── app.js           # Auto-detects environment for API URL
│   ├── index.html
│   ├── nginx.conf
│   └── Dockerfile
├── database/
│   └── init.sql
├── k8s/                      # Kubernetes Manifests (GitOps)
│   ├── namespace.yaml
│   ├── postgres-pvc.yaml
│   ├── postgres-deployment.yaml
│   ├── postgres-service.yaml
│   ├── book-api-deployment.yaml
│   ├── book-api-service.yaml
│   ├── book-ui-deployment.yaml
│   ├── book-ui-service.yaml
│   ├── ingress.yaml
│   ├── secret-store.yaml     # Azure Key Vault connection
│   ├── external-secret.yaml  # Secret sync configuration
│   ├── ACR-AUTHENTICATION.md
│   └── README.md
├── terraform/                # Infrastructure as Code (ACI + Key Vault)
│   ├── aci.tf               # Container Instances
│   ├── keyvault.tf          # App Key Vault
│   ├── modules.tf           # Azure modules (RG, ACR)
│   ├── versions.tf          # Provider configuration
│   ├── variables.tf         # Input variables
│   └── outputs.tf           # Output values
├── argocd-app.yaml          # ArgoCD Application manifest
├── docker-compose.yml        # Local development
├── start.ps1                 # Local dev helper script
└── README.md
```

---

## 🔌 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login

### Books
- `GET /api/books` - Get all books
- `GET /api/books/:id` - Get single book with reviews
- `POST /api/books` - Add new book (authenticated)
- `GET /api/books/search/:query` - Search books

### Reviews
- `GET /api/reviews/book/:bookId` - Get reviews for a book
- `POST /api/reviews` - Add review (authenticated)
- `PUT /api/reviews/:id` - Update review (authenticated)
- `DELETE /api/reviews/:id` - Delete review (authenticated)

---

## 🔒 Security Features

- **JWT authentication** with expiration
- **Password hashing** with bcrypt
- **SQL injection protection** with parameterized queries
- **Azure Managed Identities** for AKS → ACR authentication
- **Azure Key Vault** for secure secret storage
- **External Secrets Operator** for automatic secret sync
- **Kubernetes RBAC** for resource access control
- **Network Policies** for pod-to-pod communication control
- **NGINX security headers**

---

## 🗄️ Database Schema

### Users Table
| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL | Primary Key |
| username | VARCHAR | Unique username |
| email | VARCHAR | Unique email |
| password_hash | VARCHAR | Bcrypt hash |
| created_at | TIMESTAMP | Creation time |

### Books Table
| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL | Primary Key |
| title | VARCHAR | Book title |
| author | VARCHAR | Author name |
| isbn | VARCHAR | ISBN number |
| description | TEXT | Book description |
| created_at | TIMESTAMP | Creation time |

### Reviews Table
| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL | Primary Key |
| user_id | INTEGER | FK → users.id |
| book_id | INTEGER | FK → books.id |
| rating | INTEGER | 1-5 stars |
| review_text | TEXT | Review content |
| created_at | TIMESTAMP | Creation time |

---

## 🔧 Configuration

### Local Development (.env)
```env
NODE_ENV=development
PORT=3000
JWT_SECRET=your-super-secret-jwt-key
DB_HOST=postgres
DB_PORT=5432
DB_NAME=bookreviews
DB_USER=postgres
DB_PASSWORD=password
```

### Azure Key Vault (AKS)
Secrets are stored in Azure Key Vault and synced to Kubernetes via External Secrets Operator:

```bash
# Secrets in Key Vault:
- db-password
- jwt-secret

# Automatically synced to Kubernetes Secret: book-review-secrets
- POSTGRES_PASSWORD
- DB_PASSWORD
- JWT_SECRET
```

### Azure DevOps Variables (ACI)
Managed via Azure DevOps Library Group:
```
db_password
jwt_secret
db_name
db_user
```

---

## 📝 CI/CD Pipelines

### Docker Build & Push Pipeline
- Triggers on changes to `book-api/` or `book-ui/`
- Builds Docker images
- Tags with commit SHA and 'latest'
- Pushes to Azure Container Registry
- Updates image tags in `k8s/*.yaml` manifests (for ArgoCD)

### Terraform Deploy Pipeline (ACI only)
- Deploys ACI infrastructure to Azure
- Creates Azure Key Vault for secrets
- Manages container instances

### GitOps Deployment (AKS)
- **No pipeline needed!**
- ArgoCD watches Git repository
- Automatically deploys on manifest changes
- Self-healing and auto-sync enabled

---

## 🚀 Getting Started with AKS Deployment

1. **Ensure platform infrastructure exists** (managed by platform team in kubernetes-platform repo)
   - AKS cluster
   - ACR integration
   - ArgoCD installed
   - External Secrets Operator installed

2. **Set up your Key Vault secrets:**
   ```bash
   cd terraform
   terraform init
   terraform apply
   # Or manually via Azure Portal
   ```

3. **Deploy the ArgoCD Application:**
   ```bash
   kubectl apply -f argocd-app.yaml
   ```

4. **Watch ArgoCD deploy your app:**
   ```bash
   kubectl get application -n argocd book-review-platform -w
   ```

5. **Access your application:**
   ```bash
   kubectl get ingress -n book-review-platform
   # Visit http://<EXTERNAL-IP>
   ```

---

## 🤝 Contributing

This is a learning project demonstrating modern cloud-native practices! Feel free to:
- Add new features
- Improve the UI/UX
- Optimize configurations
- Add tests
- Improve documentation

## 📚 Related Repositories

- **kubernetes-platform** - Shared AKS infrastructure, managed by platform team

## 📄 License

MIT License - feel free to use this project for learning purposes.