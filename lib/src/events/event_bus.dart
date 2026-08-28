// Event types for the agent pub/sub bus (spec 013).
class LLMChunkEvent {
  final String chunk;
  LLMChunkEvent(this.chunk);
}

/// Typed pub/sub event bus (spec 013, FR-001 / FR-003).
///
/// `on<T>` registers a listener; `emit<T>` delivers synchronously to every
/// listener in registration order. Request/response lives in
/// [registerHandler] / [request].
class EventBus {
  final Map<Type, List<void Function(Object)>> _subscribers = {};

  /// Register [listener] for events of type [T]. Delivery is synchronous and in
  /// registration order (FR-003).
  void on<T>(void Function(T) listener) {
    (_subscribers[T] ??= []).add((e) => listener(e as T));
  }

  /// Deliver [event] to all subscribers of its type, in registration order.
  void emit<T>(T event) {
    final subs = _subscribers[T];
    if (subs == null) return;
    for (final sub in [...subs]) {
      sub(event as Object);
    }
  }
}
