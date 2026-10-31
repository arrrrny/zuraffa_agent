// HAND-CURATED — bounded stream buffer (issue arrrrny/zuraffa_agent#123).
//
// The backpressure seam between a chunk producer (the LLM provider's SSE
// stream) and its consumer (the engine loop's event path). The producer is
// push-based and can outrun any sink; this buffer bounds the in-flight
// window and converts consumer slowness into producer pause — TCP-grade
// backpressure — instead of unbounded memory growth.
//
// Pure dart:async; no dart:io (constitution VII). Generic over T.

import 'dart:async';
import 'dart:collection';

/// Forwards [source] through a buffer bounded at [capacity] events.
///
/// ## The streaming contract (issue #123)
///
/// * **Order and completeness.** Every data event and error is forwarded
///   exactly once, in producer order. Nothing is dropped, duplicated, or
///   reordered — including across pause/resume.
/// * **Pause propagates.** When the consumer pauses the returned stream's
///   subscription, delivery stops immediately: events accumulate in the
///   buffer until it reaches [capacity] (the high watermark), then the
///   PRODUCER is paused. For an HTTP chunk stream that means the response
///   socket stops being read and TCP backpressure reaches the provider.
/// * **Bounded memory.** The buffer never grows past [capacity] in
///   steady state. A small number of in-flight events may still arrive
///   between the pause request and the producer honoring it; the watermark
///   is enforced again on the next event.
/// * **Resume drains.** When the consumer resumes, buffered events deliver
///   first; once the buffer drains to [lowWatermark] (`capacity ~/ 2`) the
///   producer is released.
/// * **Completion.** `done` is forwarded after the buffer drains (a paused
///   consumer sees buffered data BEFORE the done event). Cancellation tears
///   down the producer subscription eagerly.
///
/// A paused consumer therefore sees: buffered chunks → (producer paused) →
/// resume → remaining chunks → done — with the provider connection quiesced
/// the whole time instead of buffering unboundedly server-side or client-side.
Stream<T> boundedStream<T>(Stream<T> source, {int capacity = 64}) {
  return _BoundedBuffer<T>(source, capacity).stream;
}

/// One buffered stream item: a data event or an error, kept distinguishable
/// so forwarding order across both kinds is preserved exactly.
sealed class _BufferedItem<T> {
  const _BufferedItem();
}

final class _BufferData<T> extends _BufferedItem<T> {
  const _BufferData(this.value);

  final T value;
}

final class _BufferedError<T> extends _BufferedItem<T> {
  const _BufferedError(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

/// Forwarding engine behind [boundedStream].
final class _BoundedBuffer<T> {
  _BoundedBuffer(this._source, int capacity)
    : capacity = capacity < 1
          ? throw ArgumentError.value(capacity, 'capacity', 'must be >= 1')
          : capacity,
      lowWatermark = capacity < 2 ? capacity : capacity ~/ 2 {
    _controller = StreamController<T>(
      onListen: () {
        _subscription = _source.listen(
          _onData,
          onError: _onError,
          onDone: _onDone,
        );
      },
      onPause: () {
        _consumerPaused = true;
      },
      onResume: () {
        _consumerPaused = false;
        _drain();
      },
      onCancel: () {
        // Tear the producer down eagerly: a cancelled consumer must not
        // leave the provider socket open or the producer delivering.
        _closed = true;
        _queue.clear();
        final subscription = _subscription;
        _subscription = null;
        return subscription?.cancel();
      },
    );
  }

  final Stream<T> _source;

  /// High watermark: reaching it pauses the producer.
  final int capacity;

  /// Low watermark: draining to it releases the producer again.
  final int lowWatermark;

  late final StreamController<T> _controller;
  StreamSubscription<T>? _subscription;
  final Queue<_BufferedItem<T>> _queue = ListQueue<_BufferedItem<T>>();

  var _sourceDone = false;
  var _sourcePaused = false;
  var _consumerPaused = false;
  var _closed = false;
  var _draining = false;

  Stream<T> get stream => _controller.stream;

  void _onData(T value) {
    if (_closed) return;
    _queue.addLast(_BufferData<T>(value));
    if (!_sourcePaused && _queue.length >= capacity) {
      _sourcePaused = true;
      _subscription?.pause();
    }
    _drain();
  }

  void _onError(Object error, StackTrace stackTrace) {
    if (_closed) return;
    _queue.addLast(_BufferedError<T>(error, stackTrace));
    _drain();
  }

  void _onDone() {
    _sourceDone = true;
    _drain();
  }

  /// Delivers as many buffered items as the consumer will take right now,
  /// then re-evaluates the producer's pause state and completion.
  void _drain() {
    if (_draining || _closed) return;
    _draining = true;
    try {
      while (_queue.isNotEmpty && !_consumerPaused && !_closed) {
        switch (_queue.removeFirst()) {
          case _BufferData<T>(:final value):
            _controller.add(value);
          case _BufferedError<T>(:final error, :final stackTrace):
            _controller.addError(error, stackTrace);
        }
      }
    } finally {
      _draining = false;
    }
    if (!_closed && _sourcePaused && _queue.length <= lowWatermark) {
      _sourcePaused = false;
      _subscription?.resume();
    }
    if (_sourceDone && _queue.isEmpty && !_closed && !_consumerPaused) {
      _closed = true;
      _controller.close();
    }
  }
}
