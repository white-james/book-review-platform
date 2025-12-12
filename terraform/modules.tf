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

# module "container_instance" {
#   source = "git::https://github.com/Azure/terraform-azurerm-avm-res-containerinstance-containergroup.git?ref=v0.2.0"

#   location            = var.azrm_resource_location
#   name                = module.naming.container_group.name
#   os_type             = "Linux"
#   resource_group_name = module.resource_group.name
#   restart_policy      = "Always"

#   # Image registry credentials for ACR
#   image_registry_credential = {
#     acr = {
#       server   = module.container_registry.resource.login_server
#       username = module.container_registry.resource.admin_username
#       password = module.container_registry.resource.admin_password
#     }
#   }

#   # Container definitions for Book Review Platform
#   containers = {
#     # PostgreSQL Database
#     postgres = {
#       name   = "postgres"
#       image  = "${module.container_registry.resource.login_server}/postgres-custom:latest"
#       cpu    = "1"
#       memory = "2"
#       ports = [
#         {
#           port     = 5432
#           protocol = "TCP"
#         }
#       ]
#       environment_variables = {
#         "POSTGRES_DB"   = var.db_name
#         "POSTGRES_USER" = var.db_user
#         "PGDATA"        = "/var/lib/postgresql/data/pgdata"
#       }
#       secure_environment_variables = {
#         "POSTGRES_PASSWORD" = var.db_password
#       }
#       volumes = {
#         postgres-data = {
#           name       = "postgres-data"
#           mount_path = "/var/lib/postgresql/data"
#           read_only  = false
#           empty_dir  = true
#         }
#       }
#     }

#     # Node.js API Backend
#     book-api = {
#       name   = "book-api"
#       image  = "${module.container_registry.resource.login_server}/book-api:latest"
#       cpu    = "1"
#       memory = "1.5"
#       ports = [
#         {
#           port     = 3000
#           protocol = "TCP"
#         }
#       ]
#       environment_variables = {
#         "NODE_ENV" = "production"
#         "PORT"     = "3000"
#         "DB_HOST"  = "localhost"
#         "DB_PORT"  = "5432"
#         "DB_NAME"  = var.db_name
#         "DB_USER"  = var.db_user
#       }
#       secure_environment_variables = {
#         "DB_PASSWORD" = var.db_password
#         "JWT_SECRET"  = var.jwt_secret
#       }
#       volumes = {}
#     }

#     # Nginx Frontend
#     book-ui = {
#       name   = "book-ui"
#       image  = "${module.container_registry.resource.login_server}/book-ui:latest"
#       cpu    = "0.5"
#       memory = "0.5"
#       ports = [
#         {
#           port     = 80
#           protocol = "TCP"
#         }
#       ]
#       environment_variables        = {}
#       secure_environment_variables = {}
#       volumes                      = {}
#     }
#   }

#   # Expose ports publicly
#   exposed_ports = [
#     {
#       port     = 80
#       protocol = "TCP"
#     },
#     {
#       port     = 3000
#       protocol = "TCP"
#     }
#   ]

#   # Public DNS configuration (generates FQDN: <dns_name_label>.<region>.azurecontainer.io)
#   dns_name_label = "${var.app_name}-${var.environment}-app"

#   tags = {
#     Environment = var.environment
#     Application = "BookReviewPlatform"
#     ManagedBy   = "Terraform"
#   }
# }

# Storage Account - Commented out for ACI deployment
# Azure Files (SMB) doesn't support the file permissions PostgreSQL requires
# This will be uncommented for AKS where we'll use Azure Disk with Persistent Volume Claims
# 
# module "storage_account" {
#   source = "git::https://github.com/Azure/terraform-azurerm-avm-res-storage-storageaccount.git?ref=v0.6.6"
#
#   location                 = var.azrm_resource_location
#   name                     = module.naming.storage_account.name
#   resource_group_name      = module.resource_group.name
#   account_kind             = "StorageV2"
#   account_replication_type = "LRS"
#   account_tier             = "Standard"
#   
#   shared_access_key_enabled = true
#   https_traffic_only_enabled = true
#   min_tls_version = "TLS1_2"
#   public_network_access_enabled = true
#   
#   network_rules = {
#     bypass         = ["AzureServices"]
#     default_action = "Allow"
#     ip_rules       = []
#     virtual_network_subnet_ids = []
#   }
#   
#   tags = {
#     Environment = var.environment
#     Application = "BookReviewPlatform"
#     ManagedBy   = "Terraform"
#   }
# }

# module "aks_cluster" {
#   source = "git::https://github.com/Azure/terraform-azurerm-avm-res-containerservice-managedcluster.git?ref=v0.3.0"

#   default_node_pool = {
#     name                 = "default"
#     vm_size              = "Standard_DS2_v2"
#     node_count           = 3
#     min_count            = 3
#     max_count            = 3
#     auto_scaling_enabled = true
#     upgrade_settings = {
#       max_surge = "10%"
#     }
#   }
#   location            = var.azrm_resource_location
#   name                = module.naming.kubernetes_cluster.name
#   resource_group_name = module.resource_group.name
#   azure_active_directory_role_based_access_control = {
#     azure_rbac_enabled = true
#     tenant_id          = data.azurerm_client_config.current.tenant_id
#   }
#   dns_prefix = "automaticexample"
#   maintenance_window_auto_upgrade = {
#     frequency   = "Weekly"
#     interval    = "1"
#     day_of_week = "Sunday"
#     duration    = 4
#     utc_offset  = "+00:00"
#     start_time  = "00:00"
#     start_date  = "2024-10-15T00:00:00Z"
#   }
#   managed_identities = {
#     system_assigned = true
#   }
# }