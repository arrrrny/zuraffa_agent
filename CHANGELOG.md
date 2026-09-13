## 0.5.0

- **Structured logging** (issue #119): `package:logging` facade with named
  subsystem loggers, level policy, and consumer-injected sinks (spec 112).
- **EngineEventBus error observability** (issue #134): default SEVERE route
  plus `EngineEventSubscriberError` so subscriber failures are observable
  instead of swallowed (spec 113).
- **JsonlSessionStorage** (issue #136): single-writer lock + streaming
  `entries()` for session persistence (spec 114).
- **Federated platform packages** (spec 115): `zuraffa_agent_android`,
  `zuraffa_agent_ios`, `zuraffa_agent_macos` over
  `zuraffa_agent_platform_interface` — the method-channel `AgentPlatform`
  seam.
- **Runnable example** (issue #111): minimal agent host app.
- All specs refined to the latest zfa template conformance (zuraffa-1.0).

## 0.4.0

- **Tool-result sanitization** (issue #118): `ToolResultSanitizer` with six
  built-in regex rules (AWS key, GitHub PAT, JWT, private-key headers,
  Slack tokens, Stripe live keys), configurable per rule, wired into
  `MissionRunner` so secret-bearing tool output is redacted before it
  reaches the model vendor.
- **Session storage schema versioning** (issue #122): `SessionSchema`
  (current version 3), JSONL header line + legacy detection + atomic
  rewrite at open, `SessionMigrator` ordered registry (1→2, 2→3),
  Hive meta-box stamp, `StoreOpenResult.schemaVersion` /
  `migratedFromVersion`. Migration policy documented in `ARCHITECTURE.md`.
- **Grader diversity** (issue #125): common `Grader` interface with
  `ExactMatchGrader`, `RegexGrader`, `JsonPathGrader` (documented subset),
  `LlmJudgeGrader` (injected completion seam), and a bind-by-id
  `GraderRegistry`.
- Built under the zfa TDD discipline: 3 specs, 34 behaviors, mutant-audited
  (bypass / migration-disabled / unknown-id mutants all killed).

## 0.3.1

- **Built on the published `zuraffa` framework (^6.2.2)** — fleet-wide
  constraint sync. No API changes.

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
