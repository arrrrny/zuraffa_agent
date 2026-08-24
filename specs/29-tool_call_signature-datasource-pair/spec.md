# Feature Specification: ToolCallSignature datasource + mock pair

**Branch**: `29-tool_call_signature-datasource-pair` | **Date**: 2026-08-24

## Summary
Hand-curated `<slug>_datasource.dart` (abstract interface) and `<slug>_mock_datasource.dart` (concrete stub) for the `ToolCallSignature` value object. Closes the two sibling issues #`29` (uri_does_not_exist) and #`30` (implements_non_class). zfa's value-object mode emits the mock_datasource that imports + implements the interface, but skips emitting the interface file itself — a self-contradictory codegen bug. This PR ships both files in the consuming repo.

## Files
- `lib/src/domain/entities/tool_call_signature/tool_call_signature.dart` — Zorphy value-object entity (hand-curated to back the datasource surface)
- `lib/src/data/datasources/tool_call_signature/tool_call_signature_datasource.dart` — abstract `ToolCallSignatureDatasource` interface
- `lib/src/data/datasources/tool_call_signature/tool_call_signature_mock_datasource.dart` — concrete `ToolCallSignatureMockDatasource` stub
- `test/data/datasources/tool_call_signature/tool_call_signature_mock_datasource_test.dart` — 3 regression tests
- `specs/29-tool_call_signature-datasource-pair/{spec,plan,tasks}.md`

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All pre-existing + 3 new tests pass

## Closes #29, closes #30
