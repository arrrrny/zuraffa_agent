# Quickstart: Production MCP transports — SSE + stdio (spec 105)

Validate the feature end-to-end on this branch.

## Prerequisites

- Dart SDK (>= 3.8.0). No other binaries; the stdio mock server runs as a
  Dart subprocess, the SSE mock server is an in-test `HttpServer` on
  loopback port 0. No external network needed.

## Run the new integration tests

```bash
dart pub get
dart test test/mcp/io_stdio_mcp_transport_test.dart
dart test test/mcp/io_sse_mcp_transport_test.dart
```

Expected: all pass, well under the 30s per-test timeout.

## Run the issue #107 hygiene gate

```bash
rg "TODO|FIXME|HACK" lib/          # expect: no matches
dart analyze                        # expect: No issues found!
dart test                           # expect: baseline 1202 + new, all green
```

## Purity gate (what CI runs)

```bash
grep -rlE "^[[:space:]]*(import|export)[[:space:]]+['\"]dart:io" lib/src/ --include="*.dart"
```

Every file printed must be in the ALLOWED list in
`.github/workflows/pipeline.yml` — this feature adds none.

## Manual smoke (optional)

```bash
dart run test/mcp/_mock_stdio_mcp_server.dart echo
```

Then type a request line and press Enter:

```json
{"jsonrpc":"2.0","id":0,"method":"tools/list","params":{}}
```

Expected: a `tools/list` result line naming the `echo` tool on stdout.
(Ctrl-C to exit.)
