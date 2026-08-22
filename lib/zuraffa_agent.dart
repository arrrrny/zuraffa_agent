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
export 'src/providers/openai_compatible_client.dart';
export 'src/tools.dart';
export 'src/skills.dart';
export 'src/engine/engine_loop.dart';
export 'src/engine/steering.dart';
export 'src/engine/stop_policy.dart';

// Entities that appear in the engine's public API. Exported so consumers can
// build an [EngineConfig] and read [EngineLoop.events] without reaching into
// `package:zuraffa_agent/src/...` (which trips `implementation_imports`).
export 'src/domain/entities/engine_event/engine_event.dart';
export 'src/domain/entities/mission_config/mission_config.dart';
export 'src/domain/entities/stop_policy/stop_policy.dart';
