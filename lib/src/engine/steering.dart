/// Steering queue management for mid-mission message injection.
///
/// Provides FIFO queue for steering messages that are injected
/// into the LLM context before the next turn execution.
library;

import 'dart:async';

/// A message queued for steering injection.
class SteeringMessage {
  /// Creates a new steering message.
  SteeringMessage({
    required this.id,
    required this.content,
    required this.injectionPoint,
  });

  /// Unique identifier for this steering message.
  final String id;

  /// The content to inject.
  final String content;

  /// The turn number at which this should be injected.
  final int injectionPoint;
}

/// FIFO queue for managing steering messages.
class SteeringQueue {
  final List<SteeringMessage> _queue = [];
  final StreamController<SteeringMessage> _controller =
      StreamController<SteeringMessage>.broadcast();

  /// Stream of steering messages as they are added.
  Stream<SteeringMessage> get messages => _controller.stream;

  /// Adds a message to the end of the queue.
  void enqueue(SteeringMessage message) {
    _queue.add(message);
    _controller.add(message);
  }

  /// Removes and returns the next message in the queue.
  SteeringMessage? dequeue() {
    if (_queue.isEmpty) return null;
    return _queue.removeAt(0);
  }

  /// Returns all messages that should be injected at or before the given turn.
  List<SteeringMessage> drainUpTo(int turnNumber) {
    final drained = <SteeringMessage>[];
    while (_queue.isNotEmpty && _queue.first.injectionPoint <= turnNumber) {
      drained.add(_queue.removeAt(0));
    }
    return drained;
  }

  /// Returns the number of pending messages.
  int get length => _queue.length;

  /// Whether the queue is empty.
  bool get isEmpty => _queue.isEmpty;

  /// Clears all messages from the queue.
  void clear() {
    _queue.clear();
  }

  /// Closes the stream controller.
  Future<void> close() async {
    await _controller.close();
  }
}