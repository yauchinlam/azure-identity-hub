locals {
  resource_group_name = "rg-${var.github_repo_name}-${var.environment}"

  hub_identity_name = "id-${var.github_repo_name}-${var.environment}-deploy"

  # Shared remote state: one storage account, unique key per repo.
  terraform_backend_state_key = "${var.github_repo_name}/${var.environment}.tfstate"

  github_oidc_subject_main = "repo:${var.github_owner}/${var.github_repo_name}:ref:refs/heads/main"
  github_oidc_subject_pull_request = "repo:${var.github_owner}/${var.github_repo_name}:pull_request"

  tags = merge(
    var.tags,
    {
      repository  = var.github_repo_name
      environment = var.environment
    }
  )

  repo_resource_group_names = {
    for repo_name, cfg in var.github_repos :
    repo_name => coalesce(cfg.resource_group_name, "rg-${repo_name}-${var.environment}")
  }

  repos_creating_resource_group = {
    for repo_name, cfg in var.github_repos :
    repo_name => cfg
    if coalesce(cfg.create_resource_group, true)
  }

  repos_using_existing_resource_group = {
    for repo_name, cfg in var.github_repos :
    repo_name => cfg
    if !coalesce(cfg.create_resource_group, true)
  }

  repo_contributor_scopes = merge(
    {
      for repo_name, cfg in var.github_repos :
      "${repo_name}-primary" => {
        repo_name = repo_name
        scope_id = coalesce(cfg.create_resource_group, true) ? azurerm_resource_group.repo[repo_name].id : data.azurerm_resource_group.repo[repo_name].id
      }
    },
    merge([
      for repo_name, cfg in var.github_repos : {
        for idx, scope_id in cfg.contributor_scopes :
        "${repo_name}-contributor-extra-${idx}" => {
          repo_name = repo_name
          scope_id  = scope_id
        }
      }
    ]...)
  )

  # Resolve scope aliases: "subscription" -> current subscription ID; otherwise use as-is.
  resolve_role_assignment_scope = {
    for repo_name, cfg in var.github_repos :
    repo_name => {
      for idx, assignment in coalesce(cfg.extra_role_assignments, []) :
      idx => assignment.scope == "subscription" ? data.azurerm_subscription.current.id : assignment.scope
    }
  }

  repo_extra_role_assignments = merge([
    for repo_name, cfg in var.github_repos : {
      for idx, assignment in coalesce(cfg.extra_role_assignments, []) :
      "${repo_name}-extra-${idx}" => {
        repo_name            = repo_name
        role_definition_name = assignment.role_definition_name
        scope_id             = local.resolve_role_assignment_scope[repo_name][idx]
      }
    }
  ]...)

  hub_user_access_admin_scope = coalesce(
    var.hub_role_assignment_scope,
    data.azurerm_subscription.current.id
  )

  repos_syncing_github_secret = {
    for repo_name, cfg in var.github_repos :
    repo_name => cfg
    if coalesce(cfg.sync_github_secret, true)
  }
}
