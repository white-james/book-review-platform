# Book Review Platform

A full-stack web application for book reviews built with Node.js, PostgreSQL, and served with Nginx. This project is designed for learning Docker and Kubernetes deployment patterns.

## 🚀 Tech Stack

- **Backend:** Node.js + Express.js (REST API)
- **Frontend:** HTML5 + Bootstrap + Vanilla JavaScript
- **Database:** PostgreSQL
- **Web Server:** Nginx (for serving static files)
- **Authentication:** JWT (JSON Web Tokens)
- **Containerization:** Docker & Docker Compose
- **Orchestration:** Kubernetes (planned)

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
│   Port: 8080    │    │   Port: 3000    │    │   Port: 5432    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🐳 Docker Setup

### Prerequisites

- Docker Desktop installed
- Docker Compose installed

### Quick Start

1. Clone this repository
2. Navigate to the project directory
3. Run with the PowerShell script (recommended):

```powershell
# Build and start all services
.\start.ps1 start

# Or use Docker Compose directly
docker-compose up --build -d
```

1. Access the application:
   - **Frontend:** http://localhost:8080
   - **API:** http://localhost:3000
   - **Database:** localhost:5432

### PowerShell Script Commands

```powershell
# Start all services (default)
.\start.ps1

# View all available commands
.\start.ps1 help

# View logs from all services
.\start.ps1 logs

# Stop all services
.\start.ps1 stop

# Restart services
.\start.ps1 restart

# Clean up (remove containers and volumes)
.\start.ps1 clean

# Build images only
.\start.ps1 build

# Show service status
.\start.ps1 status
```

### Manual Docker Compose Commands

```bash
# Build individual services
docker-compose build book-api
docker-compose build book-ui

# Start specific services
docker-compose up postgres
docker-compose up book-api
docker-compose up book-ui

# View logs
docker-compose logs -f book-api
docker-compose logs -f book-ui

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

## 📁 Project Structure

```
book-review-platform/
├── book-api/                 # Node.js Backend
│   ├── routes/
│   │   ├── auth.js          # Authentication routes
│   │   ├── books.js         # Book management routes
│   │   └── reviews.js       # Review management routes
│   ├── middleware/
│   │   └── auth.js          # JWT authentication middleware
│   ├── server.js            # Main application server
│   ├── package.json         # Node.js dependencies
│   ├── Dockerfile           # Backend container config
│   └── .env.example         # Environment variables template
├── book-ui/                  # Frontend
│   ├── css/
│   │   └── style.css        # Custom styles
│   ├── js/
│   │   └── app.js           # Frontend JavaScript
│   ├── index.html           # Main HTML page
│   ├── nginx.conf           # Nginx configuration
│   └── Dockerfile           # Frontend container config
├── database/
│   └── init.sql             # Database initialization script
└── docker-compose.yml       # Multi-container configuration
```

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
- `GET /api/reviews/user/:userId` - Get reviews by user
- `POST /api/reviews` - Add review (authenticated)
- `PUT /api/reviews/:id` - Update review (authenticated)
- `DELETE /api/reviews/:id` - Delete review (authenticated)

## 🗄️ Database Schema

### Users Table
- `id` (Primary Key)
- `username` (Unique)
- `email` (Unique)
- `password_hash`
- `created_at`

### Books Table
- `id` (Primary Key)
- `title`
- `author`
- `isbn`
- `description`
- `created_at`

### Reviews Table
- `id` (Primary Key)
- `user_id` (Foreign Key → users.id)
- `book_id` (Foreign Key → books.id)
- `rating` (1-5)
- `review_text`
- `created_at`

## 🔒 Environment Variables

Create a `.env` file in the `book-api` directory:

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

## 🧪 Testing the Application

1. **Register a new user** at http://localhost:8080
2. **Login** with your credentials
3. **Add a new book** using the "Add New Book" button
4. **Browse books** and click on any book to see details
5. **Write reviews** by clicking "Write a Review" on any book
6. **View your reviews** in the "My Reviews" section

## 📝 Development Notes

### Docker Optimization Features
- **Multi-stage builds** for smaller production images
- **Non-root users** for security
- **Health checks** for all services
- **Volume persistence** for database data
- **Network isolation** between services

### Security Features
- JWT authentication with expiration
- Password hashing with bcrypt
- SQL injection protection with parameterized queries
- XSS protection with input sanitization
- Nginx security headers

### Performance Features
- Database indexing for common queries
- Nginx gzip compression
- Static asset caching
- Connection pooling for database

## 🚢 Next Steps (Kubernetes)

This project is designed to be deployed to Kubernetes. Future additions will include:

- Kubernetes manifests (Deployments, Services, ConfigMaps)
- Helm charts for easy deployment
- Persistent Volume Claims for database storage
- Ingress configuration for routing
- Horizontal Pod Autoscaling
- Azure Container Registry integration
- Azure Kubernetes Service (AKS) deployment

## 🤝 Contributing

This is a learning project! Feel free to:
- Add new features
- Improve the UI/UX
- Optimize Docker configurations
- Add tests
- Improve documentation

## 📄 License

MIT License - feel free to use this project for learning purposes.