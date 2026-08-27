// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#15 (spec 015-mcp-client).
//
// ToolListingCache — wraps an McpClient.listTools() call with a
// TTL-based cache that is invalidated by:
//   1. Max-age expiry (default 60s — Spec 015 FR-005).
//   2. The client's onToolsChanged notification (Spec 015 FR-005).
//   3. Explicit invalidate() call from a consumer.
//
// Pattern: pure wrapper, no dart:io. Injected McpClock so tests are
// deterministic.

import 'dart:async';

import 'mcp_client.dart';
import 'mcp_reconnect_policy.dart' show McpClock;
import 'mcp_tool_descriptor.dart';

/// Cache wrapper around [McpClient.listTools].
///
/// Construction:
///   ```dart
///   final cache = ToolListingCache(
///     client: myClient,
///     maxAge: const Duration(seconds: 60),
///     now: () => DateTime.now(),
///   );
///   final tools = await cache.getOrRefresh();
///   ```
///
/// On construction, subscribes to [McpClient.onToolsChanged] and
/// invalidates the cache when the server reports a tools-changed
/// notification.
class ToolListingCache {
  final McpClient client;
  final Duration maxAge;
  final McpClock _now;

  List<McpToolDescriptor>? _cached;
  DateTime? _cachedAt;
  StreamSubscription<void>? _sub;

  ToolListingCache({
    required this.client,
    this.maxAge = const Duration(seconds: 60),
    required McpClock now,
  }) : _now = now {
    _sub = client.onToolsChanged.listen((_) => invalidate());
  }

  /// Returns the cached tool list if it's still fresh; otherwise
  /// re-lists from [client]. Throws if [client.listTools] throws.
  Future<List<McpToolDescriptor>> getOrRefresh() async {
    final now = _now();
    if (_cached != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < maxAge) {
      return List.unmodifiable(_cached!);
    }
    final fresh = await client.listTools();
    _cached = fresh;
    _cachedAt = now;
    return List.unmodifiable(fresh);
  }

  /// Explicitly invalidate the cache. The next [getOrRefresh] call
  /// will re-list from [client].
  void invalidate() {
    _cached = null;
    _cachedAt = null;
  }

  /// Whether the cache currently holds a fresh entry.
  bool get hasFreshEntry {
    if (_cached == null || _cachedAt == null) return false;
    return _now().difference(_cachedAt!) < maxAge;
  }

  /// Tear down the subscription to [McpClient.onToolsChanged]. Must
  /// be called when the cache is no longer in use to avoid leaks.
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _cached = null;
    _cachedAt = null;
  }
}
