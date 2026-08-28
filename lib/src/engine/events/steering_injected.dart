part of 'engine_event.dart';

/// Emitted by the steering layer when an injected system message overrides the loop's next-iteration context. Pairs with spec-002 steering.
final class SteeringInjected extends EngineEvent {
  @override
  final DateTime emittedAt;
  final String content;
  final DateTime injectedAt;

  const SteeringInjected({required this.emittedAt, required this.content, required this.injectedAt});
}
