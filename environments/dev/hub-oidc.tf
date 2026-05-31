resource "azurerm_federated_identity_credential" "hub_github_main" {
  name                      = "fc-${var.github_repo_name}-${var.environment}-github-main"
  user_assigned_identity_id = azurerm_user_assigned_identity.hub.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = local.github_oidc_subject_main
}
