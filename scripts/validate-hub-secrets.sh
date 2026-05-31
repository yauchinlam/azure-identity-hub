#!/usr/bin/env bash
set -euo pipefail

# Validate required GitHub Actions secrets on the hub repo before Terraform runs.
# Exits non-zero when sync_github_secret is enabled for any repo but REPO_SECRET_SYNC_TOKEN is unset.

missing=()

require() {
  local name="$1"
  local value="$2"
  if [[ -z "${value}" ]]; then
    missing+=("${name}")
  fi
}

require "AZURE_CLIENT_ID" "${AZURE_CLIENT_ID:-}"
require "AZURE_TENANT_ID" "${AZURE_TENANT_ID:-}"
require "AZURE_SUBSCRIPTION_ID" "${AZURE_SUBSCRIPTION_ID:-}"
require "AZURE_LOCATION" "${AZURE_LOCATION:-}"
require "TF_VAR_github_owner" "${TF_VAR_github_owner:-}"
require "HUB_SETTINGS_TFVARS" "${HUB_SETTINGS_TFVARS:-}"

if ((${#missing[@]} > 0)); then
  echo "Missing required hub secrets:"
  printf '  - %s\n' "${missing[@]}"
  exit 1
fi

repos_file="${1:-github_repos.tfvars.json}"
if [[ ! -f "${repos_file}" ]]; then
  echo "Repo roster not found: ${repos_file}"
  exit 1
fi

# sync_github_secret defaults to true when omitted (matches variables.tf).
sync_enabled_count="$(jq '[.github_repos // {} | to_entries[] | select(.value.sync_github_secret != false)] | length' "${repos_file}")"

if [[ "${sync_enabled_count}" -gt 0 ]]; then
  if [[ -z "${REPO_SECRET_SYNC_TOKEN:-}" ]]; then
    msg="REPO_SECRET_SYNC_TOKEN is required: ${sync_enabled_count} repo(s) have sync_github_secret enabled (default true)."
    if [[ "${STRICT_SYNC_TOKEN:-false}" == "true" ]]; then
      echo "${msg}"
      echo "Create a fine-grained PAT with Secrets write on vended repos, then:"
      echo "  gh secret set REPO_SECRET_SYNC_TOKEN --repo <owner>/azure-identity-hub"
      exit 1
    fi
    echo "::warning::${msg} Set the secret before merging to main."
  else
    echo "Secret sync enabled for ${sync_enabled_count} repo(s); REPO_SECRET_SYNC_TOKEN is set."
  fi
else
  echo "No repos configured for secret sync (sync_github_secret=false for all entries)."
fi

echo "Hub secrets validation passed."
