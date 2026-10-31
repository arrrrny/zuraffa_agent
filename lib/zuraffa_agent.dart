/// zuraffa_agent — the agent engine of the Zuraffa ecosystem.
///
/// Provides granular typed state entities, branching session trees,
/// selective compaction, and ported pi_agent support assets.
library;

export 'src/compaction.dart';
// LLM provider seam (spec 007; used by the example and integrations).
export 'src/data/providers/llm_client/llm_client_provider.dart';
export 'src/engine/events/engine_event.dart';
export 'src/engine/events/engine_event_log.dart';
export 'src/hive_adapters.dart';
export 'src/hive_session_store.dart';
export 'src/jsonl_session_storage.dart';
export 'src/llm/llm_transport.dart';
// Structured logging (spec 112, issue #119).
export 'src/logging/agent_log.dart';
export 'src/logging/memory_log_sink.dart';
export 'src/mcp/in_proc_mcp_client.dart';
export 'src/mcp/mcp_call_result.dart';
// MCP client runtime (spec 015-mcp-client).
// Pure surface — IO-segregated adapters (io_sse_mcp_transport.dart,
// io_stdio_mcp_transport.dart) are NOT exported here; downstream
// consumers inject the appropriate adapter into the client.
export 'src/mcp/mcp_client.dart';
export 'src/mcp/mcp_reconnect_policy.dart';
export 'src/mcp/mcp_tool_adapter.dart';
export 'src/mcp/mcp_tool_descriptor.dart';
export 'src/mcp/mcp_wire.dart';
export 'src/mcp/sse_mcp_client.dart';
export 'src/mcp/stdio_mcp_client.dart';
export 'src/mcp/tool_listing_cache.dart';
export 'src/observability/crash_reporter.dart';
export 'src/observability/health_check.dart';
export 'src/observability/metrics.dart';
export 'src/observability/traced_adapters.dart';
// Observability (issue #133): tracing, metrics, health, crash boundary.
// Interfaces + no-op defaults; consumers inject vendor adapters
// (package:opentelemetry / Prometheus / Sentry / OTLP).
export 'src/observability/tracing.dart';
// Host platform seam (spec 115).
export 'src/platform/agent_home_resolver.dart';
export 'src/platform/agent_platform.dart';
export 'src/platform/secure_store.dart';
export 'src/providers.dart';
export 'src/retention.dart';
// Security audit trail (issue #132): AuditLog interface, hashing helpers,
// and the append-only JSONL sink with retention-by-rotation.
export 'src/security/audit_hashing.dart';
export 'src/security/audit_log.dart';
export 'src/security/jsonl_audit_sink.dart';
export 'src/session.dart';
// Session identity: advisory single-writer lock.
export 'src/session_lock.dart';
export 'src/session_storage.dart';
export 'src/session_storage_impl.dart';
export 'src/skills.dart';
export 'src/tools.dart';
export 'src/types.dart';
export 'src/usage_ledger.dart';
