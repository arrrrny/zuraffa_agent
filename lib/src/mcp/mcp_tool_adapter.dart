// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#15 (spec 015-mcp-client).
//
// McpToolAdapter — surfaces MCP-server-advertised tools into the
// engine's ToolRegistry (lib/src/engine/tool_registry.dart).
//
// On construction:
//   - Calls [McpClient.listTools] once (via [ToolListingCache] for caching).
//   - Registers each tool into [ToolRegistry.registerMcpTool] with the
//     `mcp:<serverId>:<toolName>` namespace convention.
//   - Subscribes to [McpClient.onToolsChanged]; on a notification,
//     re-lists and diffs the new tool set against the previous one —
//     new tools are registered, gone tools are unregistered.
//
// Pattern: pure wrapper, no dart:io. Uses the existing ToolRegistry
// interface (no concrete registry required to test — a fake suffices).

import 'dart:async';

import '../domain/entities/agent_tool/agent_tool.dart';
import '../engine/tool_registry.dart';
import 'mcp_client.dart';
import 'tool_listing_cache.dart';

/// Wraps an [McpClient] and a [ToolRegistry]; surfaces MCP tools into
/// the engine's tool registry.
///
/// Construction:
///   ```dart
///   final adapter = McpToolAdapter(
///     client: myMcpClient,
///     registry: myToolRegistry,
///     serverId: 'raptorr',
///   );
///   await adapter.sync(); // initial sync
///   // onToolsChanged is wired — no further sync() calls needed unless
///   // the consumer wants to force a re-sync.
///   ```
class McpToolAdapter {
  final McpClient client;
  final ToolRegistry registry;
  final String serverId;

  /// Cache that wraps [McpClient.listTools] with TTL invalidation.
  /// Defaults to 60s max-age; configurable via [maxAge].
  final ToolListingCache _cache;

  /// Currently-registered tool names — used to diff on the next sync.
  final Set<String> _registeredNames = {};

  StreamSubscription<void>? _sub;
  bool _disposed = false;

  McpToolAdapter({
    required this.client,
    required this.registry,
    required this.serverId,
    Duration maxAge = const Duration(seconds: 60),
    required DateTime Function() now,
  }) : _cache = ToolListingCache(
          client: client,
          maxAge: maxAge,
          now: now,
        );

  /// Build the fully-qualified registry name for an MCP tool.
  ///
  /// Convention (from lib/src/engine/tool_registry.dart): MCP tools are
  /// prefixed with `mcp:<serverId>:`.
  String qualifyName(String toolName) => 'mcp:$serverId:$toolName';

  /// Initial sync: list tools via cache, register each into the
  /// registry. Safe to call repeatedly; on subsequent calls, diffs
  /// against the previously-registered set.
  Future<void> sync() async {
    if (_disposed) {
      throw StateError('McpToolAdapter.sync called after dispose');
    }
    final tools = await _cache.getOrRefresh();
    final freshNames = <String>{};
    for (final desc in tools) {
      final qualified = qualifyName(desc.name);
      freshNames.add(qualified);
      // Always re-register — if the descriptor changed (e.g. new
      // paramsSchema), unregister+register is the safe path.
      if (_registeredNames.contains(qualified)) {
        await registry.unregister(qualified);
      }
      await registry.registerMcpTool(
        AgentTool(
          id: qualified,
          description: desc.description,
          paramsSchema: desc.paramsSchema,
        ),
        serverId,
      );
    }
    // Unregister gone tools.
    for (final old in _registeredNames.difference(freshNames)) {
      await registry.unregister(old);
    }
    _registeredNames
      ..clear()
      ..addAll(freshNames);
  }

  /// Start listening to [McpClient.onToolsChanged] — when the server
  /// reports a tools-changed notification, invalidates the cache and
  /// re-syncs. Idempotent.
  Future<void> startAutoSync() async {
    if (_sub != null) return;
    _sub = client.onToolsChanged.listen((_) async {
      _cache.invalidate();
      try {
        await sync();
      } catch (_) {
        // Auto-sync failures are swallowed — the next onToolsChanged
        // notification will retry. Manual sync() re-throws.
      }
    });
  }

  /// Tear down the auto-sync subscription. The cache is also disposed.
  Future<void> dispose() async {
    _disposed = true;
    await _sub?.cancel();
    _sub = null;
    await _cache.dispose();
  }
}
