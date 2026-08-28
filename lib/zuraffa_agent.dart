/// zuraffa_agent — the agent engine of the Zuraffa ecosystem.
///
/// Provides granular typed state entities, branching session trees,
/// selective compaction, and ported pi_agent support assets.
library;

export 'src/types.dart';
export 'src/session_storage.dart';
export 'src/session_storage_impl.dart';
export 'src/jsonl_session_storage.dart';
export 'src/session.dart';
export 'src/compaction.dart';
export 'src/usage_ledger.dart';
export 'src/hive_session_store.dart';
export 'src/hive_adapters.dart';
export 'src/providers.dart';
export 'src/tools.dart';
export 'src/skills.dart';
export 'src/engine/events/engine_event.dart';
export 'src/engine/events/engine_event_log.dart';

// MCP client runtime (spec 015-mcp-client).
// Pure surface — IO-segregated adapters (io_sse_mcp_transport.dart,
// io_stdio_mcp_transport.dart) are NOT exported here; downstream
// consumers inject the appropriate adapter into the client.
export 'src/mcp/mcp_client.dart';
export 'src/mcp/mcp_tool_descriptor.dart';
export 'src/mcp/mcp_call_result.dart';
export 'src/mcp/mcp_wire.dart';
export 'src/mcp/mcp_reconnect_policy.dart';
export 'src/mcp/in_proc_mcp_client.dart';
export 'src/mcp/sse_mcp_client.dart';
export 'src/mcp/stdio_mcp_client.dart';
export 'src/mcp/tool_listing_cache.dart';
export 'src/mcp/mcp_tool_adapter.dart';
