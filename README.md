# zuraffa_agent

A pure-Dart agent engine for building autonomous, tool-using AI agents.

`zuraffa_agent` provides typed session state, branching and resumable sessions, selective context compaction, provider-agnostic LLM integration, tool dispatch, and safety policies. It has no Flutter dependency and runs on the Dart VM, servers, and CLI applications.

## Features

- Typed, serializable agent messages, turns, tool calls, usage records, and engine events.
- JSONL and Hive-compatible session storage implementations.
- Branching session trees with fork, switch, resume, and deterministic context reconstruction.
- Selective compaction with structured summaries and artifact references.
- Provider-agnostic `LlmClient` interfaces and OpenAI-compatible client support.
- Tool definitions with JSON Schema parameter validation.
- Turn limits, timeouts, repetition detection, steering messages, and typed lifecycle events.

## Installation

```yaml
dependencies:
  zuraffa_agent: ^0.1.0
```

Then fetch dependencies:

```bash
dart pub get
```

## Quick start

```dart
import 'package:zuraffa_agent/zuraffa_agent.dart';

final mission = MissionConfig(
  missionId: 'hello-001',
  initialPrompt: 'Say hello',
  availableTools: const [],
  metadata: const {},
);
```

See the generated [quick start guide](.zread/wiki/versions/2026-08-19-103026/2-quick-start.md) and the examples in `test/` for complete storage and engine-loop usage.

## Development

```bash
dart pub get
dart analyze --fatal-infos
dart test
```

## License

MIT. See [LICENSE](LICENSE).
