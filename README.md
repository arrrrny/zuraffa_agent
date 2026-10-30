# zuraffa_agent

The agent engine of the Zuraffa ecosystem: missions, sessions, tool and
MCP orchestration, an eval harness, and event-driven observability for
building type-safe AI agents with [Zuraffa](https://pub.dev/packages/zuraffa)
clean-architecture conventions.

## Getting started

```yaml
dependencies:
  zuraffa_agent: ^0.1.0
```

```dart
import 'package:zuraffa_agent/zuraffa_agent.dart';
```

The engine is organized as inside-out slices over typed ports:

- **missions / engine** — the mission runner and engine loop with a typed
  event bus.
- **session storage** — pluggable persistence (in-memory, JSONL, Hive) with
  compaction.
- **llm** — provider configuration over a swappable transport port.
- **mcp** — Model Context Protocol client plumbing and tool bridging.
- **eval** — scenario-driven evaluation with graders and reports.
- **di** — Zuraffa-style composition-root registration.

See the `zuraffa` package for the underlying UseCase/Result/DI
foundations.

## Development

```bash
dart pub get
dart run build_runner build --delete-conflicting-outputs
dart test
dart analyze
```

## Supported LLM providers

The `llm` slice speaks three wire protocols out of the box. Every client
takes a swappable `LlmTransport` (retry, circuit breaking, and the fallback
chain are layered on top), streams over SSE, and serializes multimodal
`ImageBlock` content in the provider's native shape.

| Provider | Client | Endpoint | Image payload |
|----------|--------|----------|---------------|
| OpenAI-compatible | `OpenAiCompatibleClient` | `POST {baseUrl}/chat/completions` | `image_url` part with a `data:` URI |
| Anthropic | `AnthropicClient` | `POST {baseUrl}/messages` | `image` block with a base64 `source` |
| Gemini | `GeminiClient` | `POST {baseUrl}/models/{model}:generateContent` | `inlineData` part (`mimeType` + base64 `data`) |

"OpenAI-compatible" covers OpenAI itself plus Kimi, Groq, vLLM, and any
gateway exposing `/chat/completions` — set `providerName` accordingly.
The three clients are contract-tested from one shared suite over recorded
wire fixtures (`test/fixtures/llm/<provider>/`), including multimodal
request construction (`generate_multimodal.json`).

### Not supported (wontfix, issue #138)

- **OpenAI Responses API** — every model the Responses API serves is
  reachable through the OpenAI-compatible Chat Completions client, and the
  Responses-only stateful features (`previous_response_id`, server-side
  conversation state) are orthogonal to zuraffa_agent's own session and
  episodic-memory model. Revisit only when a deployment requires those
  features specifically.
- **AWS Bedrock** — requires SigV4 request signing and the AWS credential
  chain: a materially different transport/auth surface with real
  maintenance cost, and no current demand. Revisit on demand.

### Token counting and pre-flight compaction

Requests are estimated client-side before each turn — context overflow is
caught before it is sent, not when the provider returns a 400. The default
`HeuristicTokenEstimator` counts ~4 characters per token; a
`TiktokenEstimator` consuming a tiktoken rank table is available when you
need higher fidelity:

```dart
final estimator = await TiktokenEstimator.load('cl100k_base.tiktoken');
final runner = MissionRunner(
  // ...executor, dispatcher, stop policy, events...
  model: Model(provider: 'openai', modelId: 'gpt-4o', contextWindow: 128000),
  tokenEstimator: estimator,
  contextCompressor: compressor,
);
```

When the pre-flight estimate reaches `model.contextWindow * 0.8`,
`MissionRunner` triggers the `ContextCompressor` proactively and replaces
the compacted head of the transcript with the snapshot it produced. Omit
`model`/`contextCompressor` to keep the pre-flight inert.

## License

BSD-3-Clause. See [LICENSE](LICENSE) and [NOTICE](NOTICE).

## Configuring the engine

`ZuraffaConfig` aggregates the six configuration sections the engine
consumes (provider, agent spec, engine loop, MCP transport, stop policy,
compaction strategy). Load it from a YAML document or an environment map,
validate it at startup, and hand it to `MissionRunner` — an invalid
configuration refuses to start before the first turn:

```dart
import 'package:zuraffa_agent/src/config/zuraffa_config_loader.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';

final config = ZuraffaConfigLoader.fromYaml(yamlDocument);
final issues = config.validate(); // List<ConfigIssue> — empty means runnable
final runner = MissionRunner(
  /* ...executor, dispatcher, stop policy, events... */
  config: config, // run() throws StateError listing every issue if invalid
);
```

Credentials never belong in the document — resolve them with a
`SecretResolver` implementation (`fromEnv` / `fromFile` / `fromVault`;
`NullSecretResolver` is the shipped stub).

Example document (each section is optional; `validate()` decides
runnability):

```yaml
provider:
  id: p1
  providerKind: openai
  baseUrl: https://llm.example.internal/api
  models: [internal/model]
  timeoutMs: 30000
agent_spec:
  id: spec-1
  name: research
  toolAllowlist: [search, read_file]
  systemPrompt: Research the topic.
engine_loop:
  id: loop-1
  sessionId: s1
  maxTurns: 8
  wallClockTimeoutMs: 60000
  repetitionThreshold: 5
mcp_transport:
  id: mcp-1
  transportType: sse
  endpoint: https://mcp.example.internal/sse
  authRequired: true
stop_policy:
  id: stop-1
  maxTurns: 16
  wallClockTimeoutMs: 0
  repetitionThreshold: 5
  enabled: true
compaction:
  id: comp-1
  sessionId: s1
  retainEntryIds: []
  summarizeEntryIds: []
  artifactRefs: []
  compactedAt: 0
```

Environment variables (all optional, prefix `ZFA_`):
`ZFA_PROVIDER_BASE_URL`, `ZFA_PROVIDER_PROVIDER_KIND`, `ZFA_PROVIDER_MODEL`,
`ZFA_PROVIDER_TIMEOUT_MS`, `ZFA_AGENT_SPEC_ID`, `ZFA_AGENT_SPEC_NAME`,
`ZFA_AGENT_SPEC_SYSTEM_PROMPT`, `ZFA_ENGINE_LOOP_MAX_TURNS`,
`ZFA_ENGINE_LOOP_SESSION_ID`, `ZFA_ENGINE_LOOP_WALL_CLOCK_TIMEOUT_MS`,
`ZFA_ENGINE_LOOP_REPETITION_THRESHOLD`, `ZFA_MCP_TRANSPORT_ENDPOINT`,
`ZFA_MCP_TRANSPORT_TYPE`, `ZFA_STOP_POLICY_MAX_TURNS`.
