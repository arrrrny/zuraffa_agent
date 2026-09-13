# Implementation Plan: Grader diversity (issue #125)

**Branch**: `111-grader-diversity` | **Date**: 2026-09-09 | **Spec**: [spec.md](./spec.md)

## Summary

`lib/src/eval/graders/`: a common `Grader` interface (id + grade(output) →
`GraderResult(passed, score, reason)`), four concrete graders —
`ExactMatchGrader`, `RegexGrader`, `JsonPathGrader` (documented subset:
`$`, dot keys, integer indices), `LlmJudgeGrader` (injected completion seam,
strict `PASS|FAIL — reason` response parsing) — and `GraderRegistry`
(bind-by-id, resolve, evaluate-in-bulk, typed unknown-id error). Pure Dart;
`dart:convert` only.

## Notes

- The issue's referenced `ui_graders` no longer exists on master — the
  common `Grader` interface is defined fresh (the issue's "refactored out of
  UiGrader" outcome, reached directly).
- The LLM judge takes an injected completion function (house
  injectable-collaborator pattern): scriptable in tests, provider-backed in
  evals. No provider constructor coupling.
- `GraderSealed` (recorded contract data) is untouched.

## Constitution Check

I/V/X PASS; VII PASS (pure files); IX n/a (result/config are plain value
objects per the 081/104 precedent, headers recorded).

## Sequencing

tdd.plan → tdd.run (interface+exact → regex → json-path → llm-judge →
registry → acceptance) → tdd.verify → PR (closes #125).
