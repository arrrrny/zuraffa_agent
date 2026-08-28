// Durable store for resumable sub-agent instances (spec 005 FR-002).
//
// Sub-agent instances must survive an engine restart and be resumable by id.
// Persistence goes through the allowlisted JsonlEntityStorage adapter, the same
// route the turn-record / usage-ledger datasources take (Constitution VII:
// platform I/O confined to allowlisted adapters). With [path] null the store is
// volatile in-memory, which keeps engine tests free of platform I/O.

import '../../../domain/entities/sub_agent_instance/sub_agent_instance.dart';
import '../jsonl_entity_storage.dart';

/// Persists and resumes [SubAgentInstance]s by id.
class SubAgentInstanceStore {
  SubAgentInstanceStore({this.path})
      : _storage = path == null
            ? null
            : JsonlEntityStorage<SubAgentInstance>(
                path: path,
                fromJson: SubAgentInstance.fromJson,
                toJson: (i) => i.toJson(),
                getId: (i) => i.id,
              );

  final String? path;
  final JsonlEntityStorage<SubAgentInstance>? _storage;
  final Map<String, SubAgentInstance> _mem = <String, SubAgentInstance>{};

  /// Writes [instance] through, keyed by its id, and returns what was stored.
  Future<SubAgentInstance> save(SubAgentInstance instance) async {
    final storage = _storage;
    if (storage != null) return storage.put(instance);
    _mem[instance.id] = instance;
    return instance;
  }

  /// Returns the persisted instance for [id], or null when none was stored.
  ///
  /// Reads through the durable file on every call, so a store constructed after
  /// a restart resumes the session tree from the leaf that was last saved.
  Future<SubAgentInstance?> resume(String id) async {
    final storage = _storage;
    if (storage != null) return storage.get(id);
    return _mem[id];
  }

  /// Every persisted instance, in no guaranteed order.
  Future<List<SubAgentInstance>> all() async {
    final storage = _storage;
    if (storage != null) return storage.getAll();
    return _mem.values.toList();
  }
}
