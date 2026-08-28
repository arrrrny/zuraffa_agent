part of 'engine_event.dart';

/// Emitted by the steering layer when an injected system message overrides the loop's next-iteration context. Pairs with spec-002 steering.
final class SteeringInjected extends EngineEvent {
  final DateTime emittedAt;
  final String content;
  final DateTime injectedAt;

  const SteeringInjected({required this.emittedAt, required this.content, required this.injectedAt});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SteeringInjected &&
          runtimeType == other.runtimeType &&
          emittedAt == other.emittedAt &&
          content == other.content &&
          injectedAt == other.injectedAt);

  @override
  int get hashCode => Object.hash(emittedAt, content, injectedAt);

  @override
  String toString() =>
      'SteeringInjected(emittedAt: $emittedAt, content: $content, injectedAt: $injectedAt)';
}
