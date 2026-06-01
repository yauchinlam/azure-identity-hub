#!/usr/bin/env bash
set -euo pipefail

# Validate required GitHub Actions secrets on the hub repo before Terraform runs.
# REPO_SECRET_SYNC_TOKEN must be a PAT stored as a hub repo secret (not a boolean flag).
# Exits non-zero on apply when sync_github_secret is enabled for any repo but the PAT secret is unset.

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
    msg="REPO_SECRET_SYNC_TOKEN (PAT) is required: ${sync_enabled_count} repo(s) have sync_github_secret enabled (default true)."
    if [[ "${STRICT_SYNC_TOKEN:-false}" == "true" ]]; then
      echo "${msg}"
      echo "Create a fine-grained PAT with Secrets read/write on vended repos, then store it as a hub secret:"
      echo "  gh secret set REPO_SECRET_SYNC_TOKEN --body \"<pat>\" --repo <owner>/azure-identity-hub"
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
