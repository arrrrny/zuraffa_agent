# zuraffa_agent — Architecture Notes

Working notes on the engine's storage and migration policy. The agent
engine is organized as inside-out slices over typed ports; this document
covers the persistence contract. (Broader architecture documentation:
see issue #108.)

## Session-tree persistence

Three `SessionStorage` backends implement the same port:

| Backend | File | Format | Use |
|---|---|---|---|
| In-memory | — | maps | tests, ephemeral sessions |
| JSONL | `lib/src/jsonl_session_storage.dart` | newline-delimited JSON, append-optimized | durable default |
| Hive | `lib/src/hive_session_store.dart` | binary boxes (`hive_ce`) | on-device |

The port is `SessionStorage` (`lib/src/session_storage.dart`): init,
append, get, active-leaf pointer, delete, close.

## Schema versioning + migration policy (spec 110, issue #122)

- **Current version**: `SessionSchema.currentVersion` (3). Bump it on every
  `SessionTreeEntry` schema change, and register a migration step for the
  version you are leaving.
- **JSONL header**: the FIRST line of every current file is
  `{"_schema":{"schemaVersion":N}}`. It is metadata, never surfaced as an
  entry.
- **Legacy files**: a JSONL file without a header is version 1 by
  definition (the entire pre-versioning corpus).
- **Migration at open**: when the on-disk version is older than current,
  `init()` migrates every raw entry map through `SessionMigrator` BEFORE
  deserialization, then rewrites the file atomically (temp file + rename)
  with the current-version header. The result reports `schemaVersion` and
  `migratedFromVersion`.
- **Downgrades are not supported**: opening a file at a version newer than
  the current one fails the open with a clear error.
- **Extending**: add a step to `SessionMigrator.standard()`'s registry
  (`fromVersion → step`), operating on the raw map (additive transforms are
  safest — `fromJson` ignores unknown keys). Add a fixture test with the
  OLD shape and assert the NEW behavior post-migration.
- **Hive**: entries are stored as hydrated objects (not raw maps), so
  value-level migrations are deferred; the meta box carries a
  `schemaVersion` stamp making the persisted version observable. A box
  without a stamp is legacy and is stamped forward at open.

## Structured logging (spec 112, issue #119)

The engine adopts `package:logging` behind the `AgentLog` facade
(`lib/src/logging/agent_log.dart`). The engine never prints — delivery is
always consumer-injected.

### Logger hierarchy

Every engine record is emitted through a named logger under the pinned
`zuraffa.agent.` parent (spec 112 FR-001):

| Subsystem | Logger name | Covers |
| --------- | ----------- | ------ |
| `llm` | `zuraffa.agent.llm` | provider clients, transport, retry/backoff |
| `mcp` | `zuraffa.agent.mcp` | MCP transports, reconnect, call results |
| `engine` | `zuraffa.agent.engine` | mission/turn loop, runner lifecycle |
| `eval` | `zuraffa.agent.eval` | eval harness, graders, suites |
| `session` | `zuraffa.agent.session` | session storage, migration |
| `eventBus` | `zuraffa.agent.eventBus` | EngineEventBus delivery diagnostics |

Off-hierarchy names are refused (`ArgumentError`) so consumer routing by
name stays reliable.

### Level policy

| Event class | Level | Examples |
| ----------- | ----- | -------- |
| transport bytes | `FINE` | wire payloads, framing details |
| lifecycle | `INFO` | mission start/complete, turn outcomes |
| resilience | `WARNING` | retry scheduled, breaker open |
| terminal failure | `SEVERE` | provider dead, mission failed terminally |

### Recommended consumer sink configuration

```dart
import 'package:logging/logging.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() {
  ZuraffaLogging.install(
    level: Level.WARNING, // or Level.ALL for verbose transport traces
    onRecord: (record) {
      // Format: time LEVEL [logger] message
      // Forward to stderr, a file, or a telemetry pipeline here.
    },
  );
}
```

`install` replaces any previous sink (never stacks). `MemoryLogSink`
(`lib/src/logging/memory_log_sink.dart`) is an in-memory collector for
tests and buffered forwarding. Before `install`, emission is silent,
never throws, and costs an `isLoggable` check (spec 112 FR-004).
