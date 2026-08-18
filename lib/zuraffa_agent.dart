/// zuraffa_agent — granular typed state layer for the Zuraffa agent engine.
///
/// Branching session trees over Hive and JSONL stores, multimodal typed
/// messages, and selective structured compaction. Ported from pi_agent with
/// attribution (see NOTICE); pure Dart, no Flutter dependency.
library;

export 'src/compaction.dart';
export 'src/execution_env.dart';
export 'src/hive_adapters.dart';
export 'src/hive_session_store.dart';
export 'src/prompt_templates.dart';
export 'src/session.dart';
export 'src/session_storage.dart';
export 'src/session_storage_impl.dart';
export 'src/skills.dart';
export 'src/sse_parser.dart';
export 'src/tools.dart';
export 'src/types.dart';
export 'src/usage_ledger.dart';
