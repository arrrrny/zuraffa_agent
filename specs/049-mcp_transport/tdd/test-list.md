---
feature: 049-mcp_transport
loop: inside-out
profile: .specify/memory/tdd-profile.md
spec_criteria: 9
planned_at: feat/specs-046-047-048-049
updated_at: feat/specs-046-047-048-049
suite_baseline: green
---

# Test List: McpTransport sealed (in-proc/SSE/stdio)

## Outer loop: acceptance behaviors

| id  | behavior                                                                       | traces  | kind    | state | test                                                        |
| --- | ------------------------------------------------------------------------------ | ------- | ------- | ----- | ----------------------------------------------------------- |
| A1  | McpTransport is a const-constructible value object with 4 required fields     | AC-1    | example | DONE  | `test/data/providers/mcp_transport/mcp_transport_provider_test.dart` |
| A2  | Value equality holds when all 4 fields are identical                          | AC-2    | example | DONE  | `test/data/providers/mcp_transport/mcp_transport_provider_test.dart` |
| A3  | Inequality is detected when any single field differs                           | AC-2    | example | DONE  | `test/data/providers/mcp_transport/mcp_transport_provider_test.dart` |
| A4  | hashCode is consistent with == (equal instances share hashCode)               | AC-3    | example | DONE  | `test/data/providers/mcp_transport/mcp_transport_provider_test.dart` |
| A5  | McpTransportService is abstract with Loggable+FailureHandler mixins           | AC-4    | example | DONE  | `test/data/providers/mcp_transport/mcp_transport_provider_test.dart` |
| A6  | McpTransportProvider implements service; both methods throw UnimplementedError | AC-5 | example | DONE | `test/data/providers/mcp_transport/mcp_transport_provider_test.dart` |
| A7  | toString includes id, transportType, and endpoint                             | AC-6    | example | DONE  | `test/data/providers/mcp_transport/mcp_transport_provider_test.dart` |
| A8  | IoSseMcpTransport implements McpWire; close() is idempotent, sets isOpen=false | AC-7 | example | DONE | `test/data/providers/mcp_transport/mcp_transport_provider_test.dart` |
| A9  | IoStdioMcpTransport implements McpWire; close() is idempotent, sets isOpen=false | AC-8 | example | DONE | `test/data/providers/mcp_transport/mcp_transport_provider_test.dart` |
| A10 | Both transport stubs start isOpen=false; open()/send() throw UnimplementedError | AC-9 | example | DONE | `test/data/providers/mcp_transport/mcp_transport_provider_test.dart` |

## Inner loop: unit behaviors

### `lib/src/mcp/io_sse_mcp_transport.dart`

| id  | behavior                                                                       | traces  | kind    | state | test                                                        |
| --- | ------------------------------------------------------------------------------ | ------- | ------- | ----- | ----------------------------------------------------------- |
| U1  | IoSseMcpTransport notifications stream is a broadcast stream                  | AC-7    | edge-1  | DONE  | `test/data/providers/mcp_transport/mcp_transport_provider_test.dart` |
| U2  | Double close does not throw                                                    | AC-7    | edge-2  | DONE  | `test/data/providers/mcp_transport/mcp_transport_provider_test.dart` |

### `lib/src/mcp/io_stdio_mcp_transport.dart`

| id  | behavior                                                                       | traces  | kind    | state | test                                                        |
| --- | ------------------------------------------------------------------------------ | ------- | ------- | ----- | ----------------------------------------------------------- |
| U3  | IoStdioMcpTransport accepts empty args list                                    | AC-8    | edge-1  | DONE  | `test/data/providers/mcp_transport/mcp_transport_provider_test.dart` |
| U4  | Double close does not throw                                                    | AC-8    | edge-2  | DONE  | `test/data/providers/mcp_transport/mcp_transport_provider_test.dart` |

## Verification commands

- Single test: `dart test <file> --plain-name "<test name>"`
- Full suite: `dart test`
- Coverage: not configured (corroboration only, never a gate)
- Mutation (changed files): deliberate hand-mutants per `/speckit.tdd.verify` Phase 4
