# Implementation Plan: LLM Provider Clients

**Branch**: `007-llm-provider-clients` | **Date**: 2026-08-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/007-llm-provider-clients/spec.md`

## Summary

The engine can describe providers (specs 051–054 value objects) but cannot call any of them. This feature adds the runtime LLM layer: a provider-agnostic `LlmClient` interface (`generate()` / `stream()` / `close()`) plus three concrete clients — OpenAI-compatible, Anthropic, and Gemini — all vendored with attribution from the dart_agent_core lineage, all tested through one shared contract suite over recorded wire fixtures. A single `LlmTransport` seam carries all HTTP so the engine stays `dart:io`-free in runtime paths; time and jitter are injected seams so retry/backoff is deterministic under test.

## Technical Context

**Language/Version**: Dart 3.11+ (pubspec SDK constraint `^3.8.0`; toolchain used in this run: Dart SDK 3.13.2 stable). Flutter 3.41+ is the ecosystem toolchain reference — the engine itself remains Flutter-free (constitution VII).

**Primary Dependencies**: Existing repo stack — `zuraffa` 6.0.0 (git, ref development; clean-arch core: NoParams/Loggable/FailureHandler), `zorphy_annotation`/`zorphy` (model-layer codegen), `hive_ce`, `json_annotation`. Ecosystem-standard stack (shelf, sqlite3, path, crypto) is the wider Zuraffa host-app toolchain; **none of those four is imported by this feature** — the client layer needs no new dependencies. Code is hand-curated against zfa/zuraffa-generated types; no new model entities requiring zorphy codegen are introduced (see Constitution Check).

**Storage**: N/A (stateless clients; fixture files under `test/fixtures/llm/`).

**Testing**: `dart test` (package:test; `mocktail` available). Single test: `dart test <file> --name "<name>"`. Shared contract suite = one parameterized `group()` executed for all three providers. No live network — a fake `LlmTransport` replays recorded fixtures.

**Target Platform**: Pure Dart (VM); consumable by Flutter host apps.

**Project Type**: library (agent engine).

**Performance Goals**: Streaming first chunk forwarded without buffering the whole response; backoff bounded (default max 4 retries, cap 30s).

**Constraints**: Engine purity — no `dart:io` outside the single allowlisted adapter (`lib/src/llm/io_llm_transport.dart`); no Flutter deps; `dart analyze --fatal-infos` clean for new files; attribution headers on all ported files (CI attribution gate).

**Scale/Scope**: 3 providers × (generate + stream + retry + errors) + shared contract suite ≈ 8 lib files, ~10 test files, ~12 fixtures.

## Constitution Check

| Principle | Verdict | How satisfied |
|-----------|---------|---------------|
| VII. Engine purity | PASS with registered exception | Clients never import `dart:io`; the single `IoLlmTransport` adapter is added to the CI allowlist in `.github/workflows/pipeline.yml` with justification (the gate's documented process for new IO adapters). |
| VIII. Attributed ports | PASS | Every file under `lib/src/llm/` opens with a dart_agent_core (MIT) port-attribution header. |
| IX. Zorphy model layer | PASS (documented precedent) | No new serialized entities; the LlmRequest/LlmResponse/LlmUsage value objects follow the hand-curated plain-Dart precedent set by `lib/src/domain/entities/llm_client/llm_client.dart` (spec 051: "plain Dart, value equality, no @Zorphy codegen, compiles without build_runner"). Runtime behavioral classes are not domain models. |
| X. Analyze pristine | PASS | Zero new analyzer issues (SC-004); verified before PR. |

## Project Structure

### Documentation (this feature)

```text
specs/007-llm-provider-clients/
├── spec.md              # this feature's contract (refined by /speckit.specify)
├── plan.md              # this file
├── tasks.md             # /speckit.tasks output
└── tdd/
    ├── test-list.md     # behaviors traced to AC-1..AC-9 / FR-001..007
    ├── cycle-log.md     # red-green evidence, appended per cycle
    └── verification.md  # /speckit.tdd.verify audit report
```

### Source Code (repository root)

```text
lib/src/llm/
├── llm_client.dart              # LlmClient interface + LlmRequest/LlmResponse/LlmResponseChunk/LlmUsage/LlmToolCall/LlmToolSpec + typed errors
├── llm_transport.dart           # LlmTransport/LlmHttpRequest/LlmHttpResponse seam (pure Dart; SSE/JSONL line stream)
├── io_llm_transport.dart        # dart:io HttpClient adapter (CI-allowlisted; attribution header)
├── llm_clock.dart               # injectable clock + jitter seed seams (deterministic retry tests)
├── retry.dart                   # shared exponential-backoff policy for 429/5xx/connection errors
├── openai_compatible_client.dart
├── anthropic_client.dart
└── gemini_client.dart

test/llm/
├── fake_llm_transport.dart      # fixture-replaying transport (test helper)
├── llm_client_contract_test.dart # shared contract suite (parameterized per provider)
├── openai_compatible_client_test.dart
├── anthropic_client_test.dart
├── gemini_client_test.dart
├── retry_test.dart
└── fixtures → test/fixtures/llm/{openai,anthropic,gemini}/…

test/fixtures/llm/
├── openai/   stream_chat.jsonl, generate.json, error_500.json, tool_fragments.jsonl, malformed_tool_args.jsonl
├── anthropic/ stream_messages.jsonl, tool_fragments.jsonl, thinking_stream.jsonl, error.json
└── gemini/   stream_lines.jsonl, tool_call.jsonl, malformed_function_call.jsonl, error.json
```

**Structure Decision**: The runtime layer gets its own `lib/src/llm/` namespace (mirrors how dart_agent_core separates provider clients from domain entities) instead of growing the hand-curated entity dirs; the spec-051 metadata entity stays untouched so its regression tests keep pinning it.

## Complexity Tracking

No constitution violations requiring justification beyond the registered purity-allowlist addition above.
