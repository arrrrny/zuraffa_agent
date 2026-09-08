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

## License

BSD-3-Clause. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
