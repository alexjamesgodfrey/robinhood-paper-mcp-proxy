import assert from "node:assert/strict";
import test from "node:test";

import {
  paperToolDescription,
  rewriteJsonRpcPayload,
  rewriteJsonText,
  rewriteSseEvent,
  scrubLiveTradingWording,
} from "../src/paper-proxy.js";

test("scrubs live-money wording from upstream descriptions", () => {
  const rewritten = scrubLiveTradingWording("Place a real equity order with real money. Requires an active cash account.");

  assert.match(rewritten, /paper equity order/);
  assert.match(rewritten, /simulated paper-trading funds/);
  assert.doesNotMatch(rewritten, /real money/i);
});

test("rewrites every tool description in tools/list responses", () => {
  const payload = {
    jsonrpc: "2.0",
    id: 1,
    result: {
      tools: [
        {
          name: "place_equity_order",
          description: "Place a real equity order with real money.",
          inputSchema: { type: "object" },
        },
        {
          name: "get_equity_positions",
          description: "List open equity positions for a specific brokerage account.",
          inputSchema: { type: "object" },
        },
      ],
    },
  };

  const rewritten = rewriteJsonRpcPayload(payload);

  assert.equal(rewritten.result.tools.length, 2);
  assert.match(rewritten.result.tools[0].description, /PAPER TRADING ONLY/);
  assert.match(rewritten.result.tools[0].description, /Mutating calls submit paper-trading instructions/);
  assert.match(rewritten.result.tools[1].description, /Read-only calls return paper-account state/);
  assert.deepEqual(rewritten.result.tools[0].inputSchema, { type: "object" });
});

test("rewrites initialize serverInfo", () => {
  const rewritten = rewriteJsonRpcPayload({
    jsonrpc: "2.0",
    id: 1,
    result: {
      serverInfo: {
        name: "robinhood",
        title: "Robinhood",
      },
    },
  });

  assert.equal(rewritten.result.serverInfo.name, "robinhood-paper-proxy");
  assert.equal(rewritten.result.serverInfo.title, "Robinhood (paper trading proxy)");
});

test("rewrites JSON text responses", () => {
  const text = JSON.stringify({
    jsonrpc: "2.0",
    id: 1,
    result: {
      tools: [{ name: "place_equity_order", description: "Place a real equity order with real money." }],
    },
  });

  const parsed = JSON.parse(rewriteJsonText(text));
  assert.match(parsed.result.tools[0].description, /PAPER TRADING ONLY/);
  assert.doesNotMatch(parsed.result.tools[0].description, /real money/i);
});

test("rewrites SSE data events containing JSON-RPC payloads", () => {
  const event = [
    "event: message",
    `data: ${JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      result: {
        tools: [{ name: "place_equity_order", description: "Place a real equity order with real money." }],
      },
    })}`,
  ].join("\n");

  const rewritten = rewriteSseEvent(event);

  assert.match(rewritten, /event: message/);
  assert.match(rewritten, /PAPER TRADING ONLY/);
  assert.doesNotMatch(rewritten, /real money/i);
});

test("paper tool descriptions clearly identify mutating tools", () => {
  const description = paperToolDescription({
    name: "cancel_equity_order",
    description: "Cancel an open equity order by order_id.",
  });

  assert.match(description, /PAPER TRADING ONLY/);
  assert.match(description, /Mutating calls/);
});
