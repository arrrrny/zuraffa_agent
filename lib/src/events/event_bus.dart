// Event types for the agent pub/sub bus (spec 013).
class LLMChunkEvent {
  final String chunk;
  LLMChunkEvent(this.chunk);
}

/// Request emitted before a tool call; a handler may return a modified response
/// (FR-002).
class BeforeToolCallRequest {
  final String toolName;
  final Map<String, Object> args;
  BeforeToolCallRequest(this.toolName, this.args);
}

/// Response a [BeforeToolCallRequest] handler returns to the emitter (FR-002).
class BeforeToolCallResponse {
  final Map<String, Object> args;
  final bool approved;
  BeforeToolCallResponse(this.args, {this.approved = true});
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

  // Request/response (FR-002).
  final Map<Type, List<Future<Object> Function(Object)>> _handlers = {};

  /// Register [handler] for requests of type [T], returning a response of type [R].
  void registerHandler<T, R>(Future<R> Function(T) handler) {
    (_handlers[T] ??= []).add((e) async => (await handler(e as T)) as Object);
  }

  /// Dispatch [event] to the most recently registered handler for its type and
  /// return its typed response. Throws [StateError] if no handler is registered.
  Future<R> request<R>(Object event) async {
    final handlers = _handlers[event.runtimeType];
    if (handlers == null || handlers.isEmpty) {
      throw StateError('No handler registered for ${event.runtimeType}');
    }
    return (await handlers.last(event)) as R;
  }
}
