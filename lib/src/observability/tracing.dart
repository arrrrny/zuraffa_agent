// Observability seam (issue #133, O-1) — tracing.
//
// A minimal OpenTelemetry-shaped `Span`/`Tracer` pair with a no-op default.
// The issue explicitly allows "adopt package:opentelemetry (or define a
// Tracer interface + no-op default)"; as a library, zuraffa_agent defines
// the interface and stays dependency-free — consumers inject an adapter
// backed by package:opentelemetry (or any vendor SDK) exactly where they
// already inject their LLM client and transports.
//
// Span tree produced by the engine runtime (child linkage via W3C
// `traceparent`):
//
//   mission.run  (one per MissionRunner.run)
//   ├── engine.turn     (one per EngineLoopExecutor.runTurn)
//   │   └── (vendor SDKs may nest their HTTP spans under it)
//   ├── tool.dispatch   (one per ToolDispatcher.dispatch)
//   └── mcp.callTool    (one per McpClient.callTool — via TracedMcpClient)
//
// Context propagation is W3C Trace Context: every [Span] renders its own
// `traceparent` header value; [Spans.withScope] makes a span ambient so
// nested `startSpan` calls inherit it as parent, and
// [Spans.propagationHeaders] feeds that value into `LlmRequest.headers`
// so the trace crosses the model-vendor HTTP boundary.

import 'dart:async';
import 'dart:math';

/// One operation within a trace. Create spans only through a [Tracer];
/// always [end] them (all engine-owned spans end on every exit path).
abstract interface class Span {
  /// Human-readable operation name, e.g. `mission.run`.
  String get name;

  /// 32-hex-character trace identifier (shared by the whole span tree).
  String get traceId;

  /// 16-hex-character span identifier (unique within the trace).
  String get spanId;

  /// The W3C `traceparent` header value for THIS span
  /// (`00-<traceId>-<spanId>-01`), ready for outbound propagation.
  String get traceparent;

  /// The parent's `traceparent`, or null for a root span.
  String? get parentTraceparent;

  /// Whether [end] has been called.
  bool get isEnded;

  /// Attaches a string/num/bool attribute (e.g. `mission.id`, `tool.name`).
  void setAttribute(String key, Object value);

  /// Records an error observed while this span was open.
  void recordError(Object error, [StackTrace? stackTrace]);

  /// Closes the span. Idempotent; a timestamp may be supplied by clocks
  /// that are not the wall clock.
  void end({DateTime? timestamp});
}

/// Span factory. The engine accepts a [Tracer] on `MissionRunner`; when
/// none is injected the no-op [NoopTracer] is used and tracing costs
/// nothing. Vendor adapters (package:opentelemetry, Sentry spans, OTLP
/// exporters) implement this interface.
abstract interface class Tracer {
  /// Starts a span named [name]. Parent resolution order:
  /// 1. explicit [parentTraceparent],
  /// 2. the ambient span ([Spans.current]) when running inside
  ///    [Spans.withScope],
  /// 3. none — the span becomes a root.
  Span startSpan(
    String name, {
    Map<String, Object?>? attributes,
    String? parentTraceparent,
  });
}

/// W3C Trace Context identifier generation (version `00`, flags `01`).
final class SpanIds {
  SpanIds._();

  static final Random _random = Random.secure();

  /// 128-bit trace id as 32 lowercase hex characters.
  static String newTraceId() => _hex(16);

  /// 64-bit span id as 16 lowercase hex characters.
  static String newSpanId() => _hex(8);

  static String _hex(int bytes) => List.generate(
    bytes,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

const Symbol _currentSpanKey = #zuraffa_agent.observability.currentSpan;

/// Ambient span scope + outbound propagation helpers.
abstract final class Spans {
  /// The span ambient in the current [Zone], or null. Set only by
  /// [withScope]; engine code running under `MissionRunner.run` sees the
  /// mission span here.
  static Span? get current => Zone.current[_currentSpanKey] as Span?;

  /// Runs [body] with [span] as the ambient span: any [Tracer.startSpan]
  /// call made (synchronously or across `await` chains) inside [body]
  /// resolves it as the parent unless an explicit parent is given.
  ///
  /// The scope lives in a [Zone], so it propagates through the `await`
  /// chains started inside [body] and is restored for every continuation.
  /// Errors from [body] flow to the awaiting caller exactly as they would
  /// without the scope.
  static Future<R> withScope<R>(Span span, Future<R> Function() body) =>
      runZoned<Future<R>>(body, zoneValues: {_currentSpanKey: span});

  /// Headers carrying the current trace context, for `LlmRequest.headers`:
  /// `{'traceparent': <value>}` when a span is available (explicit [span],
  /// else [current]), otherwise an empty map.
  static Map<String, String> propagationHeaders([Span? span]) {
    final s = span ?? current;
    if (s == null) return const {};
    return {'traceparent': s.traceparent};
  }
}

/// The default tracer: spans are structural no-ops that still carry
/// well-formed W3C identifiers, so propagation helpers stay correct and
/// wiring a real exporter later changes nothing but the injection.
class NoopTracer implements Tracer {
  const NoopTracer();

  static const NoopTracer instance = NoopTracer();

  @override
  Span startSpan(
    String name, {
    Map<String, Object?>? attributes,
    String? parentTraceparent,
  }) => _NoopSpan(name: name, parentTraceparent: parentTraceparent);
}

final class _NoopSpan implements Span {
  _NoopSpan({required this.name, this.parentTraceparent})
    : _traceId = SpanIds.newTraceId(),
      _spanId = SpanIds.newSpanId();

  @override
  final String name;
  @override
  final String? parentTraceparent;

  final String _traceId;
  final String _spanId;
  bool _ended = false;

  @override
  String get traceId => _traceId;

  @override
  String get spanId => _spanId;

  @override
  String get traceparent => '00-$_traceId-$_spanId-01';

  @override
  bool get isEnded => _ended;

  @override
  void setAttribute(String key, Object value) {}

  @override
  void recordError(Object error, [StackTrace? stackTrace]) {}

  @override
  void end({DateTime? timestamp}) {
    _ended = true;
  }
}

/// In-memory [Tracer] for tests and local diagnostics — records every
/// started [RecordingSpan] in start order (the observability counterpart
/// of `MemoryLogSink`).
class RecordingTracer implements Tracer {
  /// Every span this tracer started, in start order.
  final List<RecordingSpan> spans = [];

  @override
  RecordingSpan startSpan(
    String name, {
    Map<String, Object?>? attributes,
    String? parentTraceparent,
  }) {
    final span = RecordingSpan(
      name: name,
      attributes: attributes,
      parentTraceparent: parentTraceparent ?? Spans.current?.traceparent,
    );
    spans.add(span);
    return span;
  }
}

/// A span recorded by [RecordingTracer]: captured attributes, errors, and
/// the standard [Span] identity surface.
final class RecordingSpan implements Span {
  RecordingSpan({
    required this.name,
    Map<String, Object?>? attributes,
    this.parentTraceparent,
  }) : attributes = Map<String, Object?>.of(attributes ?? const {}),
       _traceId = SpanIds.newTraceId(),
       _spanId = SpanIds.newSpanId();

  @override
  final String name;
  @override
  final String? parentTraceparent;

  /// Live attribute map — [setAttribute] mutates it.
  final Map<String, Object?> attributes;

  /// Errors passed to [recordError], in order.
  final List<Object> errors = [];

  final String _traceId;
  final String _spanId;
  DateTime? _endedAt;

  @override
  String get traceId => _traceId;

  @override
  String get spanId => _spanId;

  @override
  String get traceparent => '00-$_traceId-$_spanId-01';

  @override
  bool get isEnded => _endedAt != null;

  @override
  void setAttribute(String key, Object value) {
    attributes[key] = value;
  }

  @override
  void recordError(Object error, [StackTrace? stackTrace]) {
    errors.add(error);
  }

  @override
  void end({DateTime? timestamp}) {
    _endedAt ??= timestamp ?? DateTime.now();
  }
}
