// Terraform Provider Requirements
terraform {
  required_providers {
    // Microsoft Azure
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.46.0"
    }
  }
}

provider "azurerm" {
  features {}
}
