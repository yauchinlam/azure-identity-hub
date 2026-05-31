resource "azurerm_resource_group" "hub" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_user_assigned_identity" "hub" {
  name                = local.hub_identity_name
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.tags
}
