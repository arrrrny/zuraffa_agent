# Tasks: R1 — Steering Message value object (spec 081)

- [x] 1. RED — wrote `test/domain/entities/steering_message/steering_message_test.dart`
       (23 tests across six groups: round-trip, typed ArgumentError
       on malformed input, equality, edge cases, toString pin, gate).
       Because the implementation already existed at branch creation
       (committed in PR #19, refined in spec 033), RED is characterized
       as "the absence of test coverage" — the first run passed
       immediately (GREEN). This is documented in `tdd/verification.md`
       as characterization-TDD rather than test-first TDD.
- [x] 2. GREEN — confirmed 23/23 tests green at branch HEAD; no source
       changes were needed (the implementation is already spec-exact).
- [x] 3. MUTATIONS — M1 `toJson` omits `injectedAt` (killed 9/23);
       M2 `fromJson`'s `requireString` returns `value.toString()` (killed
       U4–U7); M3 `fromJson` swallows missing/wrong-type/unparseable
       `injectedAt` (killed U8–U10); M4 `==` ignores `injectedAt` (killed
       U14); M5 `==` always-true (killed U12–U15); M6 `toString` no
       truncation (killed U23). One at a time, `cp`-restored, each
       KILLED. 6/6 killed.
- [x] 4. GATES — `dart analyze --fatal-infos` exit 0 on
       `test/domain/entities/steering_message/steering_message_test.dart`
       and `lib/src/domain/entities/steering_message/steering_message.dart`
       ("No issues found!"). Full `dart test` green: baseline 1073/2 +
       23 new = 1096/2. Pre-existing analyzer findings on unrelated
       files (1 warning + 2 info at HEAD `29b7fef`) explicitly NOT
       regressed.
- [x] 5. `tdd/verification.md` — verdict PASS, full FR coverage table,
       mutation evidence verbatim, characterization-TDD honestly
       labeled, test-first evidence (RED = absence of coverage),
       gates, findings, the non-UTC timestamp note (U20), and the
       verdict.
- [x] 6. COMMIT (artifacts + test file together — NO source changes)
       and open PR with base `master` titled `feat(081): steering
       message value object — JSON contract & equality` closing #92.
