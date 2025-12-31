terraform {
  required_version = ">=1.9.0, <2.0.0"
  required_providers {

    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.12.0, < 5.0.0"
    }
  }
  backend "azurerm" {
  }
}


provider "azurerm" {
  features {
  }
  subscription_id = var.azrm_subscription_id
  tenant_id       = var.azrm_tenant_id
}