#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${CODEX_CONFIG_PATH:-${HOME}/.codex/config.toml}"
PROXY_URL="${ROBINHOOD_PAPER_PROXY_URL:-http://127.0.0.1:18787/mcp/trading}"

mkdir -p "$(dirname "${CONFIG_PATH}")"
touch "${CONFIG_PATH}"

TMP_PATH="$(mktemp "${CONFIG_PATH}.tmp.XXXXXX")"

awk '
  function is_managed_robinhood_table(line) {
    return line ~ /^\[mcp_servers\.robinhood(\]|\.)/ || line ~ /^\[mcp_servers\.robinhood_paper(\]|\.)/
  }

  /^\[/ {
    skip = is_managed_robinhood_table($0)
    if (skip == 1) {
      next
    }
  }

  skip != 1 {
    print
  }
' "${CONFIG_PATH}" > "${TMP_PATH}"

{
  printf "\n[mcp_servers.robinhood_paper]\n"
  printf "url = \"%s\"\n" "${PROXY_URL}"
} >> "${TMP_PATH}"

mv "${TMP_PATH}" "${CONFIG_PATH}"

echo "Configured Codex to expose only mcp__robinhood_paper for Robinhood access."
echo "Removed any direct mcp_servers.robinhood entry from ${CONFIG_PATH}."
