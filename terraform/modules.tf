##############################################################
#######                    Modules                     #######
##############################################################

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.0"
  prefix  = [var.app_name, var.environment]
}

module "resource_group" {
  source   = "git::https://github.com/Azure/terraform-azurerm-avm-res-resources-resourcegroup.git?ref=0.2.1"
  location = var.azrm_resource_location
  name     = module.naming.resource_group.name
}

module "container_registry" {
  source                   = "git::https://github.com/Azure/terraform-azurerm-avm-res-containerregistry-registry.git?ref=0.4.0"
  name                     = module.naming.container_registry.name
  location                 = var.azrm_resource_location
  resource_group_name      = module.resource_group.name
  admin_enabled            = true
  sku                      = "Basic"
  retention_policy_in_days = null #ACR retention policy can only be applied when using the Premium Sku.
  # need to override this default setting because zone redundancy isn't supported on Basic SKU.
  zone_redundancy_enabled = false
}

module "container_instance" {
  source = "git::https://github.com/Azure/terraform-azurerm-avm-res-containerinstance-containergroup.git?ref=v0.2.0"

  location            = var.azrm_resource_location
  name                = module.naming.container_group.name
  os_type             = "Linux"
  resource_group_name = module.resource_group.name
  restart_policy      = "Always"

  # Image registry credentials for ACR
  image_registry_credential = {
    acr = {
      server   = module.container_registry.resource.login_server
      username = module.container_registry.resource.admin_username
      password = module.container_registry.resource.admin_password
    }
  }

  # Container definitions for Book Review Platform
  containers = {
    # PostgreSQL Database
    postgres = {
      name   = "postgres"
      image  = "${module.container_registry.resource.login_server}/postgres-custom:latest"
      cpu    = "1"
      memory = "2"
      ports = [
        {
          port     = 5432
          protocol = "TCP"
        }
      ]
      environment_variables = {
        "POSTGRES_DB"   = var.db_name
        "POSTGRES_USER" = var.db_user
        "PGDATA"        = "/var/lib/postgresql/data/pgdata"
      }
      secure_environment_variables = {
        "POSTGRES_PASSWORD" = var.db_password
      }
      volumes = {
        postgres-data = {
          name       = "postgres-data"
          mount_path = "/var/lib/postgresql/data"
          read_only  = false
          empty_dir  = true
        }
      }
    }

    # Node.js API Backend
    book-api = {
      name   = "book-api"
      image  = "${module.container_registry.resource.login_server}/book-api:1736221"
      cpu    = "1"
      memory = "1.5"
      ports = [
        {
          port     = 3000
          protocol = "TCP"
        }
      ]
      environment_variables = {
        "NODE_ENV" = "production"
        "PORT"     = "3000"
        "DB_HOST"  = "localhost"
        "DB_PORT"  = "5432"
        "DB_NAME"  = var.db_name
        "DB_USER"  = var.db_user
      }
      secure_environment_variables = {
        "DB_PASSWORD" = var.db_password
        "JWT_SECRET"  = var.jwt_secret
      }
      volumes = {}
    }

    # Nginx Frontend
    book-ui = {
      name   = "book-ui"
      image  = "${module.container_registry.resource.login_server}/book-ui:1736276"
      cpu    = "0.5"
      memory = "0.5"
      ports = [
        {
          port     = 80
          protocol = "TCP"
        }
      ]
      environment_variables        = {}
      secure_environment_variables = {}
      volumes                      = {}
    }
  }

  # Expose ports publicly
  exposed_ports = [
    {
      port     = 80
      protocol = "TCP"
    },
    {
      port     = 3000
      protocol = "TCP"
    }
  ]

  # Public DNS configuration (generates FQDN: <dns_name_label>.<region>.azurecontainer.io)
  dns_name_label = "${var.app_name}-${var.environment}-app"

  tags = {
    Environment = var.environment
    Application = "BookReviewPlatform"
    ManagedBy   = "Terraform"
  }
}