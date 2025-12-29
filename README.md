# Book Review Platform

A full-stack web application for book reviews built with Node.js, PostgreSQL, and served with Nginx. This project demonstrates modern cloud-native development practices with multiple deployment options.

## 🚀 Tech Stack

- **Backend:** Node.js + Express.js (REST API)
- **Frontend:** HTML5 + Bootstrap + Vanilla JavaScript
- **Database:** PostgreSQL
- **Web Server:** Nginx (for serving static files)
- **Authentication:** JWT (JSON Web Tokens)
- **Containerization:** Docker & Docker Compose
- **Infrastructure as Code:** Terraform
- **Cloud Platform:** Microsoft Azure (ACI & AKS)
- **CI/CD:** Azure DevOps Pipelines

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
| **Azure Kubernetes Service** | Terraform + AKS + Helm | Production-grade deployment |

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
├── Terraform manages AKS cluster
├── Helm for NGINX Ingress Controller
├── Kubernetes Ingress for routing
├── Persistent Volumes for database
└── User-assigned Managed Identities for security
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
- **Container Group** - Runs all three containers (UI, API, PostgreSQL)

### Deployment

```powershell
cd terraform

# Initialize Terraform
terraform init

# Plan deployment (ACI)
terraform plan -var="deployment_target=aci"

# Apply
terraform apply -var="deployment_target=aci"
```

---

## ☸️ Option 3: Azure Kubernetes Service (AKS)

Deploy to AKS for a production-grade, scalable Kubernetes environment.

### Prerequisites

- Azure subscription
- Azure CLI installed
- Terraform installed
- kubectl installed
- Helm installed
- Azure DevOps (for CI/CD)

### Infrastructure Components

- **Resource Group** - Logical container for resources
- **Azure Container Registry (ACR)** - Private Docker registry
- **AKS Cluster** - Managed Kubernetes cluster
- **User-Assigned Managed Identities** - Secure authentication
  - Control Plane Identity - Manages Azure resources
  - Kubelet Identity - Pulls images from ACR
- **NGINX Ingress Controller** - Routes traffic via Helm
- **Kubernetes Resources:**
  - Namespace
  - Deployments (postgres, book-api, book-ui)
  - Services (ClusterIP)
  - Ingress (path-based routing)
  - PersistentVolumeClaim (database storage)
  - Secrets (database credentials, JWT)

### Architecture

```
                    ┌─────────────────────────────────────────┐
                    │           Azure Kubernetes Service       │
                    │                                          │
Internet ──────────▶│  ┌─────────────────────────────────┐    │
                    │  │      NGINX Ingress Controller    │    │
                    │  │         (LoadBalancer IP)        │    │
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
                    └─────────────────────────────────────────┘
```

### Deployment

```powershell
cd terraform

# Initialize Terraform
terraform init

# Plan deployment (AKS)
terraform plan -var="deployment_target=aks"

# Apply
terraform apply -var="deployment_target=aks"
```

### Accessing the Application

```powershell
# Get AKS credentials
az aks get-credentials --resource-group <rg-name> --name <aks-name>

# Get the Ingress IP
kubectl get ingress -n book-review-platform

# Access the app at http://<INGRESS_IP>
```

### Useful kubectl Commands

```powershell
# View all resources
kubectl get all -n book-review-platform

# View pod logs
kubectl logs -l app=book-api -n book-review-platform

# Restart deployments
kubectl rollout restart deployment/book-api -n book-review-platform

# Check Ingress status
kubectl describe ingress book-review-ingress -n book-review-platform
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
├── terraform/                # Infrastructure as Code
│   ├── modules.tf           # Azure modules (RG, ACR, AKS)
│   ├── kubernetes.tf        # K8s resources (deployments, services, ingress)
│   ├── versions.tf          # Provider configuration
│   ├── variables.tf         # Input variables
│   └── outputs.tf           # Output values
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
- **Azure Managed Identities** for secure ACR access (no stored credentials)
- **Kubernetes Secrets** for sensitive configuration
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

## 🔧 Environment Variables

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

### Azure (via Terraform variables)
```hcl
db_password = "secure-password"
jwt_secret  = "secure-jwt-secret"
db_name     = "bookreviews"
db_user     = "postgres"
```

---

## 📝 CI/CD Pipelines

### Docker Build & Push Pipeline
- Triggers on changes to `book-api/` or `book-ui/`
- Builds Docker images
- Pushes to Azure Container Registry

### Terraform Deploy Pipeline
- Deploys infrastructure to Azure
- Supports both ACI and AKS targets
- Manages Kubernetes resources

---

## 🤝 Contributing

This is a learning project! Feel free to:
- Add new features
- Improve the UI/UX
- Optimize Docker/Terraform configurations
- Add tests
- Improve documentation

## 📄 License

MIT License - feel free to use this project for learning purposes.