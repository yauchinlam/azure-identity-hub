data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

data "azurerm_resource_group" "shared_tfstate" {
  name = var.shared_tfstate.resource_group_name
}

data "azurerm_storage_account" "shared_tfstate" {
  name                = var.shared_tfstate.storage_account_name
  resource_group_name = data.azurerm_resource_group.shared_tfstate.name
}

data "azurerm_storage_container" "shared_tfstate" {
  name                 = var.shared_tfstate.container_name
  storage_account_id   = data.azurerm_storage_account.shared_tfstate.id
}

data "azurerm_resource_group" "repo" {
  for_each = local.repos_using_existing_resource_group

  name = local.repo_resource_group_names[each.key]
}
