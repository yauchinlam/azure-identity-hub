resource "azurerm_role_assignment" "hub_contributor" {
  scope                            = azurerm_resource_group.hub.id
  role_definition_name             = "Contributor"
  principal_id                     = azurerm_user_assigned_identity.hub.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "hub_tfstate_blob_contributor" {
  scope                            = data.azurerm_storage_container.shared_tfstate.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_user_assigned_identity.hub.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "hub_user_access_administrator" {
  scope                            = local.hub_user_access_admin_scope
  role_definition_name             = "User Access Administrator"
  principal_id                     = azurerm_user_assigned_identity.hub.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "hub_contributor_subscription" {
  scope                            = data.azurerm_subscription.current.id
  role_definition_name             = "Contributor"
  principal_id                     = azurerm_user_assigned_identity.hub.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
