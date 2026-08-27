# TDD Cycle Log: AgentTool entity + RiskTier enum — classification, registry persistence, hash contract

Append only. Newest last. Every entry's `red` block is the evidence that the
test existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 626 passed, 0 failed (~27s)
- analyze: `dart analyze --fatal-infos` -> No issues found
- commit: `34b47f8`
- recorded: cycle 0, before any change

## Probe (pre-planning evidence, 2026-08-27)

The suspected scaffold hashCode violation was verified BEFORE being written
into the spec (031 discipline — claims are tested, not assumed):

```text
dart run tool/probe_agent_tool_hash.dart  (probe since removed; script at
/home/z/my-project/scripts/probe_agent_tool_hash.dart)
  a == b: true
  a.hashCode: 518580394
  b.hashCode: 128524753
  CONTRACT VIOLATION (equal objects, different hashes)
```

Two tools with distinct-but-equal `paramsSchema` map instances: `==` is true
(deep `_mapEq`) while `Object.hash(..., paramsSchema)` hashes the Map by
identity. Unlike spec 031's scaffold (contract-legal, poor distribution),
this is a genuine `==`/`hashCode` violation — A1 is a live red, not a
regression guard.
