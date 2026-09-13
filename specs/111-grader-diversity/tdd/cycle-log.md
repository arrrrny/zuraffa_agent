# TDD Cycle Log: Grader diversity (spec 111)

## Baseline

- **planned_at**: 2026-09-09, branch `111-grader-diversity` (off post-#146 master)
- **suite**: 1278 passed, 0 failed, ~2 skipped; analyzer clean
- **evidence note**: the issue's referenced `lib/src/eval/ui_graders/` no
  longer exists on master — the common `Grader` interface is defined fresh.
- **misfire protocol**: user-authorized report-and-continue (same as 105–110).

## Cycle 1 — interface + exact + regex (U1, U2, U7-options)

### RED

```
$ dart test test/eval/graders/
  32 compile errors (grader.dart / exact_match / regex / json_path / llm_judge / registry absent)
```

### GREEN

`Grader` interface — `grade` made ASYNC during the cycle so the llm-judge
grader implements it directly (deterministic graders complete synchronously
within the future). Mechanics fixes recorded: `TokenUsage` lives inside
`chat_completion.dart`; `RegExp` cannot be const inside a const
constructor; JsonPathGrader is non-const constructible.

## Cycle 2 — json-path subset (U3, U4)

### GREEN

Raw-map walker over the decoded payload: root `$`, dot properties, integer
indices. One real bug caught by U3 during implementation: `replaceAll`
does not expand `$1` capture groups (index tokens came out as literal
`$1`) — fixed with `replaceAllMapped`.

## Cycle 3 — llm-judge (U5–U7)

### GREEN

Injected `LlmComplete` seam; strict PASS/FAIL prefix parsing with
`—`/`--`/`: ` reason separators; unparsable responses fail quoting the raw
response; the judge message carries prompt + output (asserted).

## Cycle 4 — registry + composed acceptance (U8, U9, A1)

### GREEN

Bind-by-id registry (typed unknown-id error, evaluateAll in bulk); the
four-family acceptance resolves each grader by id and grades the shared
fixture.

```
$ dart test  → 1288 passed / 0 failed; dart analyze → No issues found!
```

## Audit mutant (post-cycle)

```
MUTANT: unknown ids mis-resolve to the first registered grader
U8: register + resolve by id; unknown id fails typed [E]
```

Killed by U8; restored exactly; eval suite green; analyze clean.
