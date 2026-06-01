#!/usr/bin/env bash
set -euo pipefail

# Sync vended deploy identity client IDs to target GitHub repository secrets.
# Requires: gh CLI, jq, terraform output, and REPO_SECRET_SYNC_TOKEN — a PAT stored
# as a GitHub Actions secret on this hub repo (Secrets read/write on vended repos).

: "${GITHUB_OWNER:?Set GITHUB_OWNER to your GitHub user or org}"
: "${REPO_SECRET_SYNC_TOKEN:?Set REPO_SECRET_SYNC_TOKEN to a PAT that can write secrets}"

export GH_TOKEN="${REPO_SECRET_SYNC_TOKEN}"

CLIENT_IDS_JSON="$(terraform output -json repo_identity_client_ids)"
SYNC_REPOS_JSON="$(terraform output -json repos_syncing_github_secret)"
TENANT_ID="$(terraform output -raw tenant_id)"
SUBSCRIPTION_ID="$(terraform output -raw subscription_id)"

if [[ -z "${CLIENT_IDS_JSON}" || "${CLIENT_IDS_JSON}" == "{}" ]]; then
  echo "No vended repo identities to sync."
  exit 0
fi

while IFS= read -r repo_name; do
  client_id="$(echo "${CLIENT_IDS_JSON}" | jq -r --arg r "${repo_name}" '.[$r]')"
  if [[ -z "${client_id}" || "${client_id}" == "null" ]]; then
    echo "Skipping ${repo_name}: no client ID in output."
    continue
  fi

  target="${GITHUB_OWNER}/${repo_name}"
  echo "Syncing secrets to ${target} ..."

  gh secret set AZURE_CLIENT_ID --body "${client_id}" --repo "${target}"
  gh secret set AZURE_TENANT_ID --body "${TENANT_ID}" --repo "${target}"
  gh secret set AZURE_SUBSCRIPTION_ID --body "${SUBSCRIPTION_ID}" --repo "${target}"

  if [[ -n "${AZURE_LOCATION:-}" ]]; then
    gh secret set AZURE_LOCATION --body "${AZURE_LOCATION}" --repo "${target}"
  fi

  gh secret set TF_VAR_github_owner --body "${GITHUB_OWNER}" --repo "${target}"
done < <(echo "${SYNC_REPOS_JSON}" | jq -r '.[]')

echo "Secret sync complete."
