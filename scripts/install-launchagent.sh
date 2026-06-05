#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NODE_BIN="${NODE_BIN:-$(command -v node)}"
LABEL="${LABEL:-com.codex.robinhood-paper-proxy}"
PORT="${ROBINHOOD_PAPER_PROXY_PORT:-18787}"
HOST="${ROBINHOOD_PAPER_PROXY_HOST:-127.0.0.1}"
UPSTREAM_URL="${ROBINHOOD_MCP_UPSTREAM_URL:-https://agent.robinhood.com/mcp/trading}"
PLIST_PATH="${HOME}/Library/LaunchAgents/${LABEL}.plist"
LOG_DIR="${HOME}/Library/Logs"
UID_VALUE="$(id -u)"

if [[ -z "${NODE_BIN}" ]]; then
  echo "node is required; set NODE_BIN=/absolute/path/to/node if it is not on PATH" >&2
  exit 1
fi

mkdir -p "${HOME}/Library/LaunchAgents" "${LOG_DIR}"

cat > "${PLIST_PATH}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>

  <key>ProgramArguments</key>
  <array>
    <string>${NODE_BIN}</string>
    <string>${ROOT_DIR}/src/paper-proxy.js</string>
  </array>

  <key>WorkingDirectory</key>
  <string>${ROOT_DIR}</string>

  <key>EnvironmentVariables</key>
  <dict>
    <key>ROBINHOOD_PAPER_TRADING_ACK</key>
    <string>1</string>
    <key>ROBINHOOD_MCP_UPSTREAM_URL</key>
    <string>${UPSTREAM_URL}</string>
    <key>ROBINHOOD_PAPER_PROXY_HOST</key>
    <string>${HOST}</string>
    <key>ROBINHOOD_PAPER_PROXY_PORT</key>
    <string>${PORT}</string>
  </dict>

  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>

  <key>StandardOutPath</key>
  <string>${LOG_DIR}/robinhood-paper-mcp-proxy.log</string>
  <key>StandardErrorPath</key>
  <string>${LOG_DIR}/robinhood-paper-mcp-proxy.err.log</string>
</dict>
</plist>
EOF

plutil -lint "${PLIST_PATH}"
launchctl bootout "gui/${UID_VALUE}" "${PLIST_PATH}" 2>/dev/null || true
launchctl bootstrap "gui/${UID_VALUE}" "${PLIST_PATH}"

echo "Installed ${LABEL}"
echo "Health check: http://${HOST}:${PORT}/healthz"
