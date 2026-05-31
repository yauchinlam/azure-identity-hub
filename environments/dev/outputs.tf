output "tenant_id" {
  description = "Azure AD tenant ID for GitHub Actions azure/login."
  value       = data.azurerm_client_config.current.tenant_id
  sensitive   = true
}

output "subscription_id" {
  description = "Azure subscription ID used by the provider for this run."
  value       = data.azurerm_client_config.current.subscription_id
  sensitive   = true
}

output "resource_group_name" {
  description = "Name of the hub resource group."
  value       = azurerm_resource_group.hub.name
}

output "resource_group_id" {
  description = "Resource ID of the hub resource group."
  value       = azurerm_resource_group.hub.id
}

output "shared_tfstate_storage_account_name" {
  description = "Shared storage account name for Terraform remote state (from terraform-infrastructure)."
  value       = data.azurerm_storage_account.shared_tfstate.name
  sensitive   = true
}

output "shared_tfstate_storage_account_id" {
  description = "Resource ID of the shared Terraform state storage account."
  value       = data.azurerm_storage_account.shared_tfstate.id
  sensitive   = true
}

output "shared_tfstate_container_name" {
  description = "Blob container name used for Terraform state files."
  value       = data.azurerm_storage_container.shared_tfstate.name
}

output "shared_tfstate_resource_group_name" {
  description = "Resource group containing the shared Terraform state storage account."
  value       = data.azurerm_resource_group.shared_tfstate.name
}

output "terraform_backend_state_key" {
  description = "State blob key for this repo in the shared tfstate container (repo-name/env.tfstate)."
  value       = local.terraform_backend_state_key
}

output "hub_identity_name" {
  description = "Name of the user-assigned managed identity for this hub's CI."
  value       = azurerm_user_assigned_identity.hub.name
}

output "hub_identity_client_id" {
  description = "Client ID of the hub deployment managed identity (GitHub secret AZURE_CLIENT_ID for this repo)."
  value       = azurerm_user_assigned_identity.hub.client_id
}

output "hub_identity_principal_id" {
  description = "Principal ID of the hub deployment managed identity."
  value       = azurerm_user_assigned_identity.hub.principal_id
  sensitive   = true
}

output "github_oidc_subject_main" {
  description = "OIDC subject trusted for deployments from the main branch of this hub repo."
  value       = local.github_oidc_subject_main
}

output "repo_identity_client_ids" {
  description = "Map of GitHub repo name to deploy identity client ID (for AZURE_CLIENT_ID in target repos)."
  value = {
    for repo_name, identity in azurerm_user_assigned_identity.repo :
    repo_name => identity.client_id
  }
}

output "repo_identity_principal_ids" {
  description = "Map of GitHub repo name to deploy identity principal ID."
  value = {
    for repo_name, identity in azurerm_user_assigned_identity.repo :
    repo_name => identity.principal_id
  }
  sensitive = true
}

output "repo_resource_group_names" {
  description = "Map of GitHub repo name to its primary resource group name."
  value       = local.repo_resource_group_names
}

output "repo_terraform_backend_state_keys" {
  description = "Map of GitHub repo name to its state blob key in the shared tfstate container."
  value = {
    for repo_name, _ in var.github_repos :
    repo_name => "${repo_name}/${var.environment}.tfstate"
  }
}

output "repo_oidc_subjects" {
  description = "Map of GitHub repo name to OIDC federated credential subject."
  value = {
    for repo_name, cfg in var.github_repos :
    repo_name => "repo:${var.github_owner}/${repo_name}:ref:refs/heads/${coalesce(cfg.branch, "main")}"
  }
}

output "repos_syncing_github_secret" {
  description = "Repo names that CI should push AZURE_CLIENT_ID to after apply."
  value       = keys(local.repos_syncing_github_secret)
}
