// HAND-CURATED — DO NOT REGENERATE VIA zfa.
//
// InMemoryToolRegistry — the concrete one-namespace registry behind the
// engine `ToolRegistry` interface (issue arrrrny/zuraffa_agent#4, R3.1:
// "registry-backed: DDA-registered tools + AgentPlugin-generated usecase
// tools + remote MCP tools, one namespace").
//
// Until this file the interface had no engine implementation: McpToolAdapter
// was tested against a fake, and the spec-003 audit (finding F3) recorded
// that no test resolves a call across tool origins at a real registry.
//
// Namespace conventions (interface contract):
//   - DDA tools: bare id (native namespace)               `fs.read`
//   - generated tools: `gen:` prefix                      `gen:usecase.report`
//   - MCP tools: `mcp:<serverId>:` prefix                 `mcp:raptorr:fetch`
//     (a pre-qualified id is accepted as-is — the McpToolAdapter passes
//     `mcp:<serverId>:<name>`; a bare one is qualified automatically).
//
// Collision policy (AgentTool.id doc + issue #4 AC "namespace collision
// safety across in-proc + remote sources"): registering a qualified name
// that is already taken is REJECTED at registration time with a
// [NamespaceCollisionEvent] (resolution: 'rejected') and a [StateError] —
// the original registration is never silently overwritten.
//
// resolve() answers qualified names exactly, plus a bare name when it
// unambiguously names exactly one registered tool; an ambiguous bare name
// (same base name from two origins) resolves to null — never a guess.
//
// Not exported from lib/zuraffa_agent.dart — consistent with the sibling
// engine runtimes (mission_runner.dart, tool_dispatcher.dart).

import 'dart:async';

import '../domain/entities/agent_tool/agent_tool.dart';
import 'tool_registry.dart';

/// One registration entry: the tool plus the bookkeeping the namespace
/// policy needs (which origin registered it, and its prefix-free name).
class _Registration {
  const _Registration({
    required this.tool,
    required this.origin,
    required this.bareName,
  });

  final AgentTool tool;
  final String origin;
  final String bareName;
}

/// In-memory implementation of [ToolRegistry]: DDA + generated + remote MCP
/// tools in one namespace, collisions rejected at registration.
class InMemoryToolRegistry implements ToolRegistry {
  InMemoryToolRegistry();

  final Map<String, _Registration> _tools = <String, _Registration>{};
  final StreamController<NamespaceCollisionEvent> _collisions =
      StreamController<NamespaceCollisionEvent>.broadcast();

  @override
  Stream<NamespaceCollisionEvent> get onCollision => _collisions.stream;

  @override
  Future<void> registerDdaTool(AgentTool tool) => _register(
    qualifiedName: tool.id,
    bareName: tool.id,
    tool: tool,
    origin: 'dda',
  );

  @override
  Future<void> registerGeneratedTool(AgentTool tool) {
    final qualified = tool.id.startsWith('gen:') ? tool.id : 'gen:${tool.id}';
    return _register(
      qualifiedName: qualified,
      bareName: qualified.substring('gen:'.length),
      tool: tool,
      origin: 'generated',
    );
  }

  @override
  Future<void> registerMcpTool(AgentTool tool, String serverId) {
    final prefix = 'mcp:$serverId:';
    final qualified = tool.id.startsWith(prefix)
        ? tool.id
        : '$prefix${tool.id}';
    return _register(
      qualifiedName: qualified,
      bareName: qualified.substring(prefix.length),
      tool: tool,
      origin: 'mcp:$serverId',
    );
  }

  @override
  Future<void> unregister(String qualifiedName) async {
    _tools.remove(qualifiedName);
  }

  @override
  Future<AgentTool?> resolve(String qualifiedName) async {
    // Exact qualified-name match first (DDA tools live under their bare id,
    // which IS their qualified name).
    final exact = _tools[qualifiedName];
    if (exact != null) return exact.tool;

    // Bare-name fallback: only when exactly one prefixed tool carries that
    // prefix-free name. Two origins sharing a base name stay ambiguous —
    // the caller must qualify (issue #4 collision safety).
    AgentTool? match;
    for (final registration in _tools.values) {
      if (registration.bareName != qualifiedName) continue;
      if (match != null) return null;
      match = registration.tool;
    }
    return match;
  }

  @override
  Future<List<AgentTool>> list() async => [
    for (final registration in _tools.values) registration.tool,
  ];

  /// Emits one collision event per rejected registration. Broadcast: with
  /// no listener the event is dropped (the StateError still carries the
  /// failure to the caller).
  void _emitCollision({
    required String qualifiedName,
    required String existingOrigin,
    required String incomingOrigin,
  }) {
    _collisions.add(
      NamespaceCollisionEvent(
        toolName: qualifiedName,
        sources: [existingOrigin, incomingOrigin],
        resolution: 'rejected',
      ),
    );
  }

  Future<void> _register({
    required String qualifiedName,
    required String bareName,
    required AgentTool tool,
    required String origin,
  }) async {
    final existing = _tools[qualifiedName];
    if (existing != null) {
      _emitCollision(
        qualifiedName: qualifiedName,
        existingOrigin: existing.origin,
        incomingOrigin: origin,
      );
      throw StateError(
        'tool namespace collision: "$qualifiedName" is already registered '
        'from ${existing.origin}; registration from $origin is rejected — '
        'collisions are never silently overwritten (issue #4 / spec-003 A1)',
      );
    }
    _tools[qualifiedName] = _Registration(
      tool: tool,
      origin: origin,
      bareName: bareName,
    );
  }

  /// Closes the collision-event stream. The registry is unusable afterwards.
  Future<void> dispose() => _collisions.close();
}
