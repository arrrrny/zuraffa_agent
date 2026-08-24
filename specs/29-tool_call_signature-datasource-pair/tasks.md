# Tasks: ToolCallSignature datasource + mock pair
- T1 Create `lib/src/domain/entities/tool_call_signature/tool_call_signature.dart` (Zorphy value object).
- T2 Create `lib/src/data/datasources/tool_call_signature/tool_call_signature_datasource.dart` (abstract class).
- T3 Create `lib/src/data/datasources/tool_call_signature/tool_call_signature_mock_datasource.dart` (concrete stub).
- T4 Create `test/data/datasources/tool_call_signature/tool_call_signature_mock_datasource_test.dart` (3 tests).
- T5 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T6 Commit + push + PR + merge + pull + re-test.
