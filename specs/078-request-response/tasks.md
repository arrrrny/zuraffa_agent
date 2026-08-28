# Tasks: Request/response pattern (spec 078)

- [x] 1. RED — write `test/events/request_response_test.dart` (8 tests:
       controller.request round-trip, controller.on alias, controller/bus
       parity, last-handler-wins, exception propagation, no-handler
       StateError, type-honesty, late registration + type independence)
       — must fail on the missing `AgentController.request` / `on` /
       `bus` members.
- [x] 2. GREEN — add the three members to `AgentController`
       (additive-only edit); full suite green.
- [x] 3. Mutations — M1 request no-delegate; M2 on no-op; M3
       first-registered dispatch; M4 swallow exceptions; M5 drop
       StateError; M6 erase the `as R` cast. One at a time, cp-restored,
       each must KILL.
- [x] 4. Gates — `dart analyze --fatal-infos` exit 0; `dart test` green
       (baseline 919/2 + new).
- [x] 5. `tdd/verification.md` — cycle integrity (RED scope honestly
       split: new surface vs pins), FR table, mutation evidence verbatim,
       gates, findings, verdict.
- [x] 6. Commit (artifacts + code together) and open PR with base
       `master`.
