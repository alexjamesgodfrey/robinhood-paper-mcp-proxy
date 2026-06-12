# Robinhood Paper MCP Proxy

Small HTTP pass-through proxy for the Robinhood MCP endpoint. It forwards the MCP protocol to the configured upstream and rewrites `tools/list` metadata so every Robinhood tool is presented as paper trading.

The proxy is intentionally generic: it does not hard-code Robinhood tool names or schemas, so new upstream tools pass through automatically. It rewrites JSON-RPC responses and SSE `data:` events that contain `result.tools`.

For paper-trading metadata, it also removes upstream real-money workflow language that says a preview/review call creates a separate explicit-confirmation gate before placement. A paper preview remains a preview; it does not add an extra confirmation requirement by itself.

## Run

```sh
ROBINHOOD_PAPER_TRADING_ACK=1 npm start
```

Optional environment:

```sh
ROBINHOOD_MCP_UPSTREAM_URL=https://agent.robinhood.com/mcp/trading
ROBINHOOD_PAPER_PROXY_HOST=127.0.0.1
ROBINHOOD_PAPER_PROXY_PORT=18787
```

`ROBINHOOD_PAPER_TRADING_ACK=1` is required so the operator explicitly asserts that the configured upstream is paper/simulation. The proxy changes MCP metadata; it does not itself simulate fills or prevent an incorrectly configured live upstream.

## Codex Config

Expose only the proxy-backed paper server to Codex:

```toml
[mcp_servers.robinhood_paper]
url = "http://127.0.0.1:18787/mcp/trading"
```

Do not also configure a direct `[mcp_servers.robinhood]` entry in Codex. The proxy still forwards to the upstream Robinhood MCP endpoint internally, but Codex only sees `mcp__robinhood_paper`, which prevents accidentally selecting the direct upstream namespace.

You can apply that config automatically:

```sh
bash scripts/configure-codex.sh
```

If a running Codex thread still shows only `mcp__robinhood`, start a new thread or reload Codex so MCP discovery reads the new server entry.

## LaunchAgent

This repo includes an installer so macOS can keep the proxy running in the background.

Install or reload it with:

```sh
bash scripts/install-launchagent.sh
```

## Health Check

```sh
curl http://127.0.0.1:18787/healthz
```

## Test

```sh
npm test
```

## License

MIT
