## 0.3.0

- **Fail-closed configuration** (issue #117): `ProviderConfigProvider` and
  `YamlAgentSpecProvider` no longer invent defaults — constructing without an
  injected configuration throws immediately. All vendor references stripped
  from non-test code. **Breaking**: no-arg construction of these two
  providers was previously possible and is now an error.
- **`ZuraffaConfig`** (issue #121): one aggregate over the six engine
  configuration sections with typed startup validation (`missing` /
  `outOfRange` / `incompatible` issues), YAML + environment loaders
  (`ZFA_*` variables), a `SecretResolver` interface, and a fail-fast gate in
  `MissionRunner.run` — an invalid configuration refuses to start before the
  first turn. README documents the contract with a working example.
- **MCP resilience** (issue #120): per-server circuit breaker (fail-fast
  `circuit-open` after N consecutive failures, cooldown probe recovery),
  per-call timeout (default 30s, typed `timeout` error, never auto-retried),
  and opt-in transient retry for read-only tools. `McpToolDescriptor` gains
  an additive `readOnly` flag.
- Built under the zfa TDD discipline: 3 specs, 40 behaviors, mutant-audited.

## 0.2.0

- Production MCP transports: `IoStdioMcpTransport` (subprocess JSON-RPC over
  stdin/stdout) and `IoSseMcpTransport` (bearer-authenticated SSE stream +
  JSON-RPC POST) replace the last `UnimplementedError` stubs — the engine can
  now talk to real MCP servers (issue #107).
- Lifecycle safety: idempotent open/close, typed `McpWireClosedException` /
  `McpWireOpenException` failures compatible with the client reconnect
  policy, pending sends drained typed on close/exit.
- Server-pushed tools-changed notifications surface on both transports;
  log noise and unknown ids are tolerated silently.
- Hygiene: zero TODO/FIXME/HACK in `lib/`; purity allowlist completed with
  the spec-076 memory adapter; built under the zfa TDD discipline (24
  behaviors, mutant-audited).

## 0.1.1

- Packaging release on the standard zuraffa package template: README,
  CHANGELOG, BSD-3 LICENSE/NOTICE, homepage/repository/issue_tracker/topics,
  and a hosted `zuraffa: ^6.1.0` dependency (was a git dependency on a
  development ref).
- Migrated all 85 specs to the current zfa spec format and ran the zfa TDD
  plan gates across the corpus (85/85 test-lists); suite 1202 passing,
  analyzer clean. Misfire on the zuraffa 6.2.1 barrel collision resolved —
  arrrrny/zuraffa#1344.

## 0.1.0

- Initial release: the agent engine of the Zuraffa ecosystem.
- Mission and session engines: typed mission runners, session storage
  (in-memory, JSONL, and Hive-backed stores), compaction, and event-driven
  engine loop with a typed `EngineEventBus`.
- LLM seam: provider configuration, HTTP transport, and a swappable
  `LlmTransport` port.
- MCP integration: client plumbing for Model Context Protocol servers with
  tool bridging into the engine.
- Eval harness: scenario-driven evaluation of missions with graders and
  reports.
- DI via the Zuraffa composition-root conventions; entities generated with
  Zorphy (`zorphy_annotation` + `json_serializable`).
- Built under the zfa TDD discipline (spec-driven red→green cycles,
  mutation-audited suites).
