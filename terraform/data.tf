data "azurerm_subscription" "this" {
  subscription_id = var.azrm_subscription_id
}

data "azurerm_client_config" "current" {
}
