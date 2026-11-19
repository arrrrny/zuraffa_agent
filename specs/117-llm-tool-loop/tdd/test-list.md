# Test list: LlmToolLoop (issue #190)

Every behavior below is observed failing (red) before its implementation in
`lib/src/llm/llm_tool_loop.dart`.

## Acceptance (outer)

- **A1** A downstream consumer names `LlmToolLoop` from the package barrel
  alone (compile-time proof).

## Unit (inner)

- **U1** The loop executes tool calls, appends results, returns the terminal
  assistant message.
- **U2** Every executed call is recorded for observability.
- **U3** `maxToolCalls` budget → `ToolLoopBudgetExceeded` (honest, not
  truncated).
- **U4** `maxTurns` budget → `ToolLoopTurnBudgetExceeded`.
- **U5** A provider error → `ToolLoopProviderError`.
- **U6** Middleware transforms each tool result before it enters the
  transcript (the PII-scrubber case).
- **U7** A tool that throws becomes an error tool result, not a crash.
- **U8** A cut-off turn (`finishReason != 'stop'`, no calls) continues the
  loop rather than ending it.
- **U9** `ToolLoopConfig` snapshot is reported back on the result.
- **U10** Advertised tools ride the request.
- **U11** A `maxToolCalls` stop mid-batch leaves no dangling `tool_use` blocks:
  every `ToolCallBlock` in the failed transcript has a matching
  `ToolResultMessage` (review finding on #192).
- **U12** A middleware that throws becomes an error tool result rather than
  escaping `run()` as a raw exception (review finding on #192).

## Traceability

| Behavior | Test | Status |
|---|---|---|
| A1 | `the loop type is reachable from the package barrel` | DONE |
| U1 | `executes tool calls and returns the terminal assistant message` | DONE |
| U2 | `records every executed call for caller observability` | DONE |
| U3 | `maxToolCalls budget fails honestly (no silent truncation)` | DONE |
| U4 | `turn budget fails honestly` | DONE |
| U5 | `a provider error surfaces as an honest failure` | DONE |
| U6 | `middleware transforms each tool result before it enters the transcript` | DONE |
| U7 | `a tool that throws becomes an error tool result, not a crash` | DONE |
| U8 | `empty tool calls with a non-stop finish still continues the loop` | DONE |
| U9 | `a config snapshot drives the loop and is reported back` | DONE |
| U10 | `advertised tools ride the request` | DONE |
| U11 | `a budget stop mid-batch leaves no dangling tool_use blocks` | DONE |
| U12 | `a middleware that throws becomes an error result, not a crash` | DONE |