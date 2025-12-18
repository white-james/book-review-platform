#############################################################
#######         Kubernetes Resources                  #######
#############################################################

# Namespace
resource "kubernetes_namespace" "book_review" {
  metadata {
    name = "book-review-platform"
    labels = {
      name        = "book-review-platform"
      environment = var.environment
    }
  }
}

# Secret from Terraform variables (populated by Azure DevOps)
resource "kubernetes_secret" "book_review_secrets" {
  metadata {
    name      = "book-review-secrets"
    namespace = kubernetes_namespace.book_review.metadata[0].name
  }

  data = {
    POSTGRES_PASSWORD = var.db_password
    DB_PASSWORD       = var.db_password
    JWT_SECRET        = var.jwt_secret
  }

  type = "Opaque"
}

# PersistentVolumeClaim for PostgreSQL
resource "kubernetes_persistent_volume_claim" "postgres" {
  metadata {
    name      = "postgres-pvc"
    namespace = kubernetes_namespace.book_review.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "managed-csi"

    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

# PostgreSQL Deployment
resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.book_review.metadata[0].name
    labels = {
      app = "postgres"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "${module.container_registry.resource.login_server}/postgres-custom:latest"

          port {
            container_port = 5432
            name           = "postgres"
          }

          env {
            name  = "POSTGRES_DB"
            value = var.db_name
          }

          env {
            name  = "POSTGRES_USER"
            value = var.db_user
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.book_review_secrets.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
          }

          resources {
            requests = {
              memory = "1Gi"
              cpu    = "500m"
            }
            limits = {
              memory = "2Gi"
              cpu    = "1000m"
            }
          }

          readiness_probe {
            exec {
              command = ["pg_isready", "-U", var.db_user]
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }

          liveness_probe {
            exec {
              command = ["pg_isready", "-U", var.db_user]
            }
            initial_delay_seconds = 30
            period_seconds        = 30
          }
        }

        volume {
          name = "postgres-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres.metadata[0].name
          }
        }
      }
    }
  }
}

# PostgreSQL Service
resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.book_review.metadata[0].name
  }

  spec {
    selector = {
      app = "postgres"
    }

    port {
      port        = 5432
      target_port = 5432
    }

    type = "ClusterIP"
  }
}

# Book API Deployment
resource "kubernetes_deployment" "book_api" {
  metadata {
    name      = "book-api"
    namespace = kubernetes_namespace.book_review.metadata[0].name
    labels = {
      app = "book-api"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "book-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "book-api"
        }
      }

      spec {
        container {
          name  = "book-api"
          image = "${module.container_registry.resource.login_server}/book-api:latest"

          port {
            container_port = 3000
            name           = "http"
          }

          env {
            name  = "NODE_ENV"
            value = "production"
          }

          env {
            name  = "PORT"
            value = "3000"
          }

          env {
            name  = "DB_HOST"
            value = kubernetes_service.postgres.metadata[0].name
          }

          env {
            name  = "DB_PORT"
            value = "5432"
          }

          env {
            name  = "DB_NAME"
            value = var.db_name
          }

          env {
            name  = "DB_USER"
            value = var.db_user
          }

          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.book_review_secrets.metadata[0].name
                key  = "DB_PASSWORD"
              }
            }
          }

          env {
            name = "JWT_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.book_review_secrets.metadata[0].name
                key  = "JWT_SECRET"
              }
            }
          }

          resources {
            requests = {
              memory = "512Mi"
              cpu    = "250m"
            }
            limits = {
              memory = "1Gi"
              cpu    = "500m"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.postgres]
}

# Book API Service
resource "kubernetes_service" "book_api" {
  metadata {
    name      = "book-api"
    namespace = kubernetes_namespace.book_review.metadata[0].name
  }

  spec {
    selector = {
      app = "book-api"
    }

    port {
      port        = 3000
      target_port = 3000
    }

    type = "ClusterIP"
  }
}

# Book UI Deployment
resource "kubernetes_deployment" "book_ui" {
  metadata {
    name      = "book-ui"
    namespace = kubernetes_namespace.book_review.metadata[0].name
    labels = {
      app = "book-ui"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "book-ui"
      }
    }

    template {
      metadata {
        labels = {
          app = "book-ui"
        }
      }

      spec {
        container {
          name  = "book-ui"
          image = "${module.container_registry.resource.login_server}/book-ui:latest"

          port {
            container_port = 80
            name           = "http"
          }

          resources {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "200m"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# Book UI Service (LoadBalancer for external access)
resource "kubernetes_service" "book_ui" {
  metadata {
    name      = "book-ui"
    namespace = kubernetes_namespace.book_review.metadata[0].name
  }

  spec {
    selector = {
      app = "book-ui"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}
