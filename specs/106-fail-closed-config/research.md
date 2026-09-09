# Research: Fail-closed provider configuration (spec 106)

## R1 — Constructor-fails-closed vs read-time sentinel?

**Decision**: constructor fails closed with `ArgumentError`.

**Rationale**: the issue lists it as the first acceptance criterion; it
fails at the earliest possible moment (composition root), before any turn
runs, and keeps `current()` a pure accessor. The sentinel alternative keeps
construction succeeding and moves the failure to first read — worse for
fail-fast startup validation, which issue #121 (the next spec) builds on.

**Alternatives considered**: `StateError` sentinel at `current()` — rejected
per above; nullable service return — rejected (interface change, out of
scope).

## R2 — What happens to the fallback chain's default provider ids?

**Decision**: de-vendor to `['anthropic', 'gemini']` — real in-tree client
kinds (spec 007 clients) — keeping the default chain structurally valid.

**Rationale**: the issue's strip criterion ("Strip `kilo.ai` /
`tencent/hy3:free` from non-test code") plus the `'kilo'` id appearing only
as that vendor's alias. Dropping the whole default would be a bigger
interface change than the issue asks for. Both remaining ids correspond to
first-party client kinds, not third-party gateway routes.

**Alternatives considered**: requiring injection here too — rejected (out of
the issue's evidence list; would ripple into fallback-chain tests without
issue mandate); empty ids list — rejected (structurally invalid chain).

## R3 — How should the integration test behave without env config?

**Decision**: skip with a stated reason naming the three required variables
(`LLM_BASE_URL`, `LLM_MODEL`, and the API key), and carry no fallback URL.

**Rationale**: the test is already env-gated by design (KIMI/LLM keys);
defaulting to a vendor was the bug. Skipping keeps it runnable locally when
an operator explicitly configures an endpoint, and honest in CI.

**Alternatives considered**: deleting the test — rejected (it is the only
live-network coverage of the LLM transport seam).
