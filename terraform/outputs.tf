##############################################################
#######                    Outputs                     #######
##############################################################

output "key_vault_name" {
  description = "Name of the Key Vault containing application secrets"
  value       = module.key_vault.resource.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault for External Secrets configuration"
  value       = module.key_vault.resource.vault_uri
}

output "acr_login_server" {
  description = "Login server for the Azure Container Registry"
  value       = module.container_registry.resource.login_server
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}
