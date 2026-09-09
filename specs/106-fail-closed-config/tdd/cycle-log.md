# TDD Cycle Log: Fail-closed provider configuration (spec 106)

Append-only record of the red-green-refactor cycles. One entry per cycle;
RED evidence quoted verbatim from the failing runs.

## Baseline

- **planned_at**: 2026-09-09, HEAD `d5dbc1f` (branch `106-fail-closed-config`)
- **suite**: 1224 passed, 0 failed, ~2 skipped (~42s wall)
- **analyzer**: `No issues found!`
- **misfire protocol**: user-authorized report-and-continue (constitution
  II/III override scoped to these runs, same as spec 105).

## Cycle 1 — ProviderConfigProvider fail-closed (U1, U2)

**Scope**: no-arg construction throws `ArgumentError` naming the missing
configuration; a configured provider serves the injected values verbatim.

### RED

```
$ dart test test/data/providers/provider_config/provider_config_provider_test.dart
00:00 +2 -1: U1: constructing without a configuration throws ArgumentError naming it [E]
  Expected: throws satisfies function
    Actual: <Closure: () => ProviderConfigProvider>
```

### GREEN

Constructor keeps the optional positional parameter (so absence is a runtime
contract violation, per the issue's "fails closed with ArgumentError if
null") and throws from `_require`. The two kilo-pinning tests were retired
with the invented-default behavior (stated reason in file header).

```
$ dart test  → 1224 passed / 0 failed; dart analyze → No issues found!
```

## Cycle 2 — YamlAgentSpecProvider fail-closed (U3, U4)

### RED

```
00:00 +2 -1: U3: constructing without a spec throws ArgumentError naming it [E]
  Expected: throws satisfies function
    Actual: <Closure: () => YamlAgentSpecProvider>
```

(One test-mechanics fix inside the cycle: a mis-written
`expect(same(spec), same(custom))` → `expect(spec, same(custom))`.)

### GREEN

Same fail-closed shape; injected-spec pin strengthened to identity.

```
$ dart test  → 1222 passed / 0 failed (−5 retired default pins, +3 new); analyzer clean
```

## Cycle 3 — de-vendor fallback default + integration test (U5, A2)

### RED

```
$ dart test test/data/providers/fallback_chain/fallback_chain_provider_test.dart --plain-name "U5:"
00:00 +0 -1: U5: default chain ids carry no vendor id (spec 106, issue #117) [E]
    Actual: ['kilo', 'anthropic', 'gemini']
```

### GREEN

Fallback default ids → `['anthropic', 'gemini']` (real in-tree client kinds).
Integration test de-vendored: env-required with stated-reason skip; the
`providerName == 'kilo'` pin removed with the vendor id.

### Spec amendment (pre-verify, documented)

FR-004/SC-002/A2 originally said "entire repository except specs"; the
search surfaced ~20 inert fixture model strings in engine unit tests —
literal test data the issue's own AC ("non-test code") never targeted.
Spec amended to the issue's scope before verify; amendment recorded here.

### A2 + A3 gates

```
$ rg -i "kilo\.ai|hy3" lib/ tool/ test/integration/  → zero hits ✓
$ rg "'kilo'" lib/                                   → zero hits ✓
$ dart analyze  → No issues found!
$ dart test     → 1223 passed / 0 failed
$ purity gate   → PASS (unchanged)
```
