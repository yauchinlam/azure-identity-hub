variable "github_owner" {
  description = "GitHub user or organization name for OIDC federated credential subjects."
  type        = string
}

variable "github_repo_name" {
  description = "GitHub repository name for this hub stack (used in resource naming)."
  type        = string
  default     = "azure-identity-hub"
}

variable "environment" {
  description = "Deployment environment suffix (for example, dev or prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "location" {
  description = "Azure region for hub and vended resource groups."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources in this stack."
  type        = map(string)
  default = {
    repository  = "azure-identity-hub"
    environment = "dev"
    managed_by  = "terraform"
  }
}

variable "shared_tfstate" {
  description = "Shared Terraform remote state storage used by vended repo identities."
  type = object({
    resource_group_name  = string
    storage_account_name = string
    container_name       = string
  })
}

variable "github_repos" {
  description = <<-EOT
    GitHub repositories to vend deploy identities for. Map key is the repository name
    (must match the GitHub repo name for OIDC subject). Each entry gets a user-assigned
    managed identity, federated credential, Contributor on its resource group, and
    Storage Blob Data Contributor on the shared tfstate container. Use extra_role_assignments
    for repo-specific exceptions beyond the default baseline.
  EOT
  type = map(object({
    create_resource_group = optional(bool, true)
    resource_group_name   = optional(string)
    branch                = optional(string, "main")
    contributor_scopes    = optional(list(string), [])
    extra_role_assignments = optional(list(object({
      role_definition_name = string
      scope                = string
    })), [])
    sync_github_secret = optional(bool, true)
  }))
  default = {}
}

variable "hub_role_assignment_scope" {
  description = <<-EOT
    Scope for User Access Administrator on the hub deploy identity. The hub identity
    needs this role to assign Contributor and Storage Blob Data Contributor to vended
    identities. Subscription scope is typical for identity vending platforms.
  EOT
  type        = string
  default     = null
}
