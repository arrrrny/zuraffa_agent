// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'branch_summary_entry.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class BranchSummaryEntry {
  BranchSummaryEntry({
    required String this.id,
    String? this.parentId,
    required DateTime this.timestamp,
    required String this.summary,
  });

  factory BranchSummaryEntry.fromJson(Map<String, dynamic> json) =>
      _$BranchSummaryEntryFromJson(json);

  final String id;

  final String? parentId;

  final DateTime timestamp;

  final String summary;

  BranchSummaryEntry copyWith({
    String? id,
    String? parentId,
    DateTime? timestamp,
    String? summary,
  }) {
    return BranchSummaryEntry(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      timestamp: timestamp ?? this.timestamp,
      summary: summary ?? this.summary,
    );
  }

  BranchSummaryEntry copyWithBranchSummaryEntry({
    String? id,
    String? parentId,
    DateTime? timestamp,
    String? summary,
  }) {
    return copyWith(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      summary: summary,
    );
  }

  BranchSummaryEntry patchWithBranchSummaryEntry([
    BranchSummaryEntryPatch? patchInput,
  ]) {
    final _patcher = patchInput ?? BranchSummaryEntryPatch();
    final _patchMap = _patcher.patchMap;
    return BranchSummaryEntry(
      id: _patchMap.containsKey(BranchSummaryEntry$.id)
          ? ((_patchMap[BranchSummaryEntry$.id] is Function)
                    ? _patchMap[BranchSummaryEntry$.id](this.id)
                    : (_patchMap[BranchSummaryEntry$.id] is Patch)
                    ? _patchMap[BranchSummaryEntry$.id].applyTo(this.id)
                    : _patchMap[BranchSummaryEntry$.id])
                as String
          : this.id,
      parentId: _patchMap.containsKey(BranchSummaryEntry$.parentId)
          ? ((_patchMap[BranchSummaryEntry$.parentId] is Function)
                    ? _patchMap[BranchSummaryEntry$.parentId](this.parentId)
                    : (_patchMap[BranchSummaryEntry$.parentId] is Patch)
                    ? _patchMap[BranchSummaryEntry$.parentId].applyTo(
                        this.parentId,
                      )
                    : _patchMap[BranchSummaryEntry$.parentId])
                as String?
          : this.parentId,
      timestamp: _patchMap.containsKey(BranchSummaryEntry$.timestamp)
          ? ((_patchMap[BranchSummaryEntry$.timestamp] is Function)
                    ? _patchMap[BranchSummaryEntry$.timestamp](this.timestamp)
                    : (_patchMap[BranchSummaryEntry$.timestamp] is Patch)
                    ? _patchMap[BranchSummaryEntry$.timestamp].applyTo(
                        this.timestamp,
                      )
                    : _patchMap[BranchSummaryEntry$.timestamp])
                as DateTime
          : this.timestamp,
      summary: _patchMap.containsKey(BranchSummaryEntry$.summary)
          ? ((_patchMap[BranchSummaryEntry$.summary] is Function)
                    ? _patchMap[BranchSummaryEntry$.summary](this.summary)
                    : (_patchMap[BranchSummaryEntry$.summary] is Patch)
                    ? _patchMap[BranchSummaryEntry$.summary].applyTo(
                        this.summary,
                      )
                    : _patchMap[BranchSummaryEntry$.summary])
                as String
          : this.summary,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BranchSummaryEntry &&
        id == other.id &&
        parentId == other.parentId &&
        timestamp == other.timestamp &&
        summary == other.summary;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.parentId, this.timestamp, this.summary);
  }

  @override
  String toString() {
    return 'BranchSummaryEntry(' +
        'id: ${id}' +
        ', ' +
        'parentId: ${parentId}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'summary: ${summary})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$BranchSummaryEntryToJson(this);
    _sanitizeJson(data);
    return data;
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension BranchSummaryEntryPropertyHelpers on BranchSummaryEntry {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasParentId {
    return this.parentId?.isNotEmpty == true;
  }

  bool get noParentId {
    return this.parentId?.isEmpty ?? true;
  }

  String get parentIdRequired {
    return this.parentId ??
        (throw StateError('parentId is required but was null'));
  }

  bool get hasSummary {
    return this.summary.isNotEmpty;
  }

  bool get noSummary {
    return this.summary.isEmpty;
  }
}

extension BranchSummaryEntrySerialization on BranchSummaryEntry {
  Map<String, dynamic> toJson() {
    return _$BranchSummaryEntryToJson(this);
  }
}

enum BranchSummaryEntry$ { id, parentId, timestamp, summary }

class BranchSummaryEntryPatch
    extends PatchBase<BranchSummaryEntry, BranchSummaryEntry$> {
  BranchSummaryEntry applyTo(BranchSummaryEntry entity) {
    return entity.patchWithBranchSummaryEntry(this);
  }

  BranchSummaryEntryPatch withId(String? value) {
    patchMap[BranchSummaryEntry$.id] = value;
    return this;
  }

  BranchSummaryEntryPatch withParentId(String? value) {
    patchMap[BranchSummaryEntry$.parentId] = value;
    return this;
  }

  BranchSummaryEntryPatch withTimestamp(DateTime? value) {
    patchMap[BranchSummaryEntry$.timestamp] = value;
    return this;
  }

  BranchSummaryEntryPatch withSummary(String? value) {
    patchMap[BranchSummaryEntry$.summary] = value;
    return this;
  }
}

/// Field descriptors for [BranchSummaryEntry] query construction
abstract final class BranchSummaryEntryFields {
  static const id = Field<BranchSummaryEntry, String>('id', _$id);

  static const parentId = Field<BranchSummaryEntry, String?>(
    'parentId',
    _$parentId,
  );

  static const timestamp = Field<BranchSummaryEntry, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const summary = Field<BranchSummaryEntry, String>(
    'summary',
    _$summary,
  );

  static String _$id(BranchSummaryEntry e) {
    return e.id;
  }

  static String? _$parentId(BranchSummaryEntry e) {
    return e.parentId;
  }

  static DateTime _$timestamp(BranchSummaryEntry e) {
    return e.timestamp;
  }

  static String _$summary(BranchSummaryEntry e) {
    return e.summary;
  }
}

extension BranchSummaryEntryCompareE on BranchSummaryEntry {
  Map<String, dynamic> compareToBranchSummaryEntry(BranchSummaryEntry other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (parentId != other.parentId) {
      diff['parentId'] = () => other.parentId;
    }

    if (timestamp != other.timestamp) {
      diff['timestamp'] = () => other.timestamp;
    }

    if (summary != other.summary) {
      diff['summary'] = () => other.summary;
    }
    return diff;
  }
}
