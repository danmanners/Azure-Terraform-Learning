// Terraform Provider Requirements
terraform {
  required_providers {
    // Microsoft Azure
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.46.0"
    }
    // Google Cloud
    google = {
      source = "hashicorp/google"
      version = "~>3.72.0"
    }

  }
  // State File
  backend "gcs" {
    bucket  = "dm-homelab-tfstate"
    prefix  = "azure/learning"
  }
}

// Azure Provider
provider "azurerm" {
  features {}
}
