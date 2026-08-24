# Feature Specification: AgentMessage (multimodal parts)

**Branch**: `041-agent_message` | **Date**: 2026-08-24

## Summary
Multimodal assistant/user message — text, image, audio, document parts — ported from pi_agent's types.dart (epic #1 §R2.1, issue #3). The atomic conversational unit the engine assembles into turns. This advances epic issue #3 (State & Sessions). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/agent_message/agent_message.dart` - `AgentMessage` value object (3 fields; value-based equality).
- `lib/src/domain/services/agent_message_service.dart` - abstract `AgentMessageService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/agent_message/agent_message_provider.dart` - concrete `AgentMessageProvider` stub (UnimplementedError bodies).
- `test/data/providers/agent_message/agent_message_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/041-agent_message/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #3 (State & Sessions)
