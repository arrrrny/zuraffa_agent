// HAND-CURATED — replaces the previous stub that threw.
//
// Durable local backing for the ToolInvocationRecord data source. When [path]
// is null (tests / ephemeral runs) it behaves as a volatile in-memory store,
// keeping engine tests deterministic and free of platform I/O. When [path] is
// provided it persists to a JSONL file via the allowlisted JsonlEntityStorage
// adapter (Constitution VII: platform I/O is confined to consciously
// allowlisted adapters). Real remote backing (HTTP/gRPC) remains a later phase.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/tool_invocation_record/tool_invocation_record.dart';
import '../jsonl_entity_storage.dart';
import 'tool_invocation_record_datasource.dart';

class ToolInvocationRecordRemoteDataSource
    with Loggable, FailureHandler
    implements ToolInvocationRecordDataSource {
  final String? path;
  final JsonlEntityStorage<ToolInvocationRecord>? _storage;
  final Map<String, ToolInvocationRecord> _mem = <String, ToolInvocationRecord>{};

  ToolInvocationRecordRemoteDataSource({this.path})
      : _storage = path == null
            ? null
            : JsonlEntityStorage<ToolInvocationRecord>(
                path: path,
                fromJson: ToolInvocationRecord.fromJson,
                toJson: (r) => r.toJson(),
                getId: (r) => r.id,
              );

  @override
  Future<ToolInvocationRecord> get(
    QueryParams<ToolInvocationRecord> params,
  ) async {
    final id = params.params?['id'] as String?;
    final found = await _read(id);
    if (found == null) {
      throw StateError('ToolInvocationRecord not found: $id');
    }
    return found;
  }

  @override
  Future<List<ToolInvocationRecord>> getList(
    ListQueryParams<ToolInvocationRecord> params,
  ) async {
    var items = await _all();
    final offset = params.offset ?? 0;
    if (offset > 0) items = items.skip(offset).toList();
    final limit = params.limit;
    if (limit != null) items = items.take(limit).toList();
    return items;
  }

  @override
  Future<ToolInvocationRecord> create(
    ToolInvocationRecord toolInvocationRecord,
  ) async {
    if (_storage != null) return _storage.put(toolInvocationRecord);
    _mem[toolInvocationRecord.id] = toolInvocationRecord;
    return toolInvocationRecord;
  }

  @override
  Future<ToolInvocationRecord> update(
    UpdateParams<String, ToolInvocationRecordPatch> params,
  ) async {
    final existing = await _read(params.id);
    if (existing == null) {
      throw StateError('ToolInvocationRecord not found: ${params.id}');
    }
    final updated = existing.patchWithToolInvocationRecord(params.data);
    if (_storage != null) return _storage.put(updated);
    _mem[params.id] = updated;
    return updated;
  }

  @override
  Future<void> delete(DeleteParams<String> params) async {
    if (_storage != null) return _storage.delete(params.id);
    _mem.remove(params.id);
  }

  Future<ToolInvocationRecord?> _read(String? id) async {
    if (id == null) return null;
    if (_storage != null) return _storage.get(id);
    return _mem[id];
  }

  Future<List<ToolInvocationRecord>> _all() async {
    if (_storage != null) return _storage.getAll();
    return _mem.values.toList();
  }
}
