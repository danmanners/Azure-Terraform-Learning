// Resource Groups
resource "azurerm_resource_group" "learning" {
  // Key Values
  name     = var.tags.project-name
  location = var.tf-region

  // Tags
  tags = merge({
      "Name" = var.tags.project-name
    },
    var.global-tags
  )
}
