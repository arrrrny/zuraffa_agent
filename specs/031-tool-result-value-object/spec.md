# Feature Specification: ToolResult value object (no id) + clean-arch layers

**Branch**: `031-tool-result-value-object` | **Date**: 2026-08-24

## Summary
Hand-curated `ToolResult` value object (no `id` field — spec-exact from `specs/003-tools-and-mcp/spec.md` §Key Entities: `content:String, structuredPayload:Map?, artifactRef:ArtifactRef?`) + `ToolResultService` interface + `ToolResultProvider` stub. Issue #31 surfaces the zfa v6.0.0 bug where `zfa make ToolResult repository usecase di mock provider service datasource` hard-requires an `id` field and aborts with a validation error instead of auto-detecting the value-object shape. This PR ships the spec-exact value object + clean-arch layers in the consuming repo, ahead of zfa's upstream fix.

## Files
- `lib/src/domain/entities/tool_result/tool_result.dart` — `ToolResult` value object (content + structuredPayload + artifactRef, no id, value-based equality, isSummarized getter).
- `lib/src/domain/services/tool_result_service.dart` — abstract `ToolResultService` (current, count — both NoParams-param).
- `lib/src/data/providers/tool_result/tool_result_provider.dart` — concrete `ToolResultProvider` stub.
- `test/data/providers/tool_result/tool_result_provider_test.dart` — 7 regression tests.
- `specs/031-tool-result-value-object/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All pre-existing + 7 new tests pass

## Closes #31
