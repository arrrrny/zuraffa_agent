// HAND-CURATED — replaces the previous stub that threw.
//
// Durable local backing for the UsageLedgerEntry data source. When [path] is
// null (tests / ephemeral runs) it behaves as a volatile in-memory store,
// keeping engine tests deterministic and free of platform I/O. When [path] is
// provided it persists to a JSONL file via the allowlisted JsonlEntityStorage
// adapter (Constitution VII: platform I/O is confined to consciously
// allowlisted adapters). Real remote backing (HTTP/gRPC) remains a later phase.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/usage_ledger_entry/usage_ledger_entry.dart';
import '../jsonl_entity_storage.dart';
import 'usage_ledger_entry_datasource.dart';

class UsageLedgerEntryRemoteDataSource
    with Loggable, FailureHandler
    implements UsageLedgerEntryDataSource {
  final String? path;
  final JsonlEntityStorage<UsageLedgerEntry>? _storage;
  final Map<String, UsageLedgerEntry> _mem = <String, UsageLedgerEntry>{};

  UsageLedgerEntryRemoteDataSource({this.path})
      : _storage = path == null
            ? null
            : JsonlEntityStorage<UsageLedgerEntry>(
                path: path,
                fromJson: UsageLedgerEntry.fromJson,
                toJson: (r) => r.toJson(),
                getId: (r) => r.id,
              );

  @override
  Future<UsageLedgerEntry> get(
    QueryParams<UsageLedgerEntry> params,
  ) async {
    final id = params.params?['id'] as String?;
    final found = await _read(id);
    if (found == null) {
      throw StateError('UsageLedgerEntry not found: $id');
    }
    return found;
  }

  @override
  Future<List<UsageLedgerEntry>> getList(
    ListQueryParams<UsageLedgerEntry> params,
  ) async {
    var items = await _all();
    final offset = params.offset ?? 0;
    if (offset > 0) items = items.skip(offset).toList();
    final limit = params.limit;
    if (limit != null) items = items.take(limit).toList();
    return items;
  }

  @override
  Future<UsageLedgerEntry> create(UsageLedgerEntry usageLedgerEntry) async {
    if (_storage != null) return _storage.put(usageLedgerEntry);
    _mem[usageLedgerEntry.id] = usageLedgerEntry;
    return usageLedgerEntry;
  }

  @override
  Future<UsageLedgerEntry> update(
    UpdateParams<String, UsageLedgerEntryPatch> params,
  ) async {
    final existing = await _read(params.id);
    if (existing == null) {
      throw StateError('UsageLedgerEntry not found: ${params.id}');
    }
    final updated = existing.patchWithUsageLedgerEntry(params.data);
    if (_storage != null) return _storage.put(updated);
    _mem[params.id] = updated;
    return updated;
  }

  @override
  Future<void> delete(DeleteParams<String> params) async {
    if (_storage != null) return _storage.delete(params.id);
    _mem.remove(params.id);
  }

  Future<UsageLedgerEntry?> _read(String? id) async {
    if (id == null) return null;
    if (_storage != null) return _storage.get(id);
    return _mem[id];
  }

  Future<List<UsageLedgerEntry>> _all() async {
    if (_storage != null) return _storage.getAll();
    return _mem.values.toList();
  }
}
