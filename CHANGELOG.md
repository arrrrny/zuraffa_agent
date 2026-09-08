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
