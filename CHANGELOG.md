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
