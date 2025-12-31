module "key_vault" {
  source = "git::https://github.com/Azure/terraform-azurerm-avm-res-keyvault-vault.git?ref=v0.10.2"

  location                      = var.azrm_resource_location
  name                          = module.naming.key_vault.name
  resource_group_name           = module.resource_group.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  public_network_access_enabled = true
  role_assignments = {
    deployment_user_kv_admin = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    },
    user1_kv_admin = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = "08d7f057-6e43-480b-8dcb-54834a013a9b"
    }
    # Grant AKS cluster access to read secrets
    aks_secrets_user = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = var.aks_kubelet_identity_object_id
    }
  }
  secrets = {
    db_password = {
      name = "db-password"
    },
    jwt_secret = {
      name = "jwt-secret"
    }
  }
  secrets_value = {
    db_password = var.db_password
    jwt_secret  = var.jwt_secret
  }
  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }
}