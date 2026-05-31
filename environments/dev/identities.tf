resource "azurerm_resource_group" "repo" {
  for_each = local.repos_creating_resource_group

  name     = local.repo_resource_group_names[each.key]
  location = var.location

  tags = merge(
    local.tags,
    {
      repository  = each.key
      environment = var.environment
      vended_by   = var.github_repo_name
    }
  )
}

resource "azurerm_user_assigned_identity" "repo" {
  for_each = var.github_repos

  name                = "id-${each.key}-${var.environment}-deploy"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name

  tags = merge(
    local.tags,
    {
      repository  = each.key
      environment = var.environment
      vended_by   = var.github_repo_name
    }
  )
}

resource "azurerm_federated_identity_credential" "repo_github_main" {
  for_each = var.github_repos

  name                      = "fc-${each.key}-${var.environment}-github-${replace(coalesce(each.value.branch, "main"), ".", "-")}"
  user_assigned_identity_id = azurerm_user_assigned_identity.repo[each.key].id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = "repo:${var.github_owner}/${each.key}:ref:refs/heads/${coalesce(each.value.branch, "main")}"
}

resource "azurerm_role_assignment" "repo_contributor" {
  for_each = local.repo_contributor_scopes

  scope                            = each.value.scope_id
  role_definition_name             = "Contributor"
  principal_id                     = azurerm_user_assigned_identity.repo[each.value.repo_name].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "repo_tfstate_blob_contributor" {
  for_each = var.github_repos

  scope                            = data.azurerm_storage_container.shared_tfstate.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_user_assigned_identity.repo[each.key].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
