// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'compaction_entry.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class CompactionEntry {
  CompactionEntry({
    required String this.id,
    String? this.parentId,
    required DateTime this.timestamp,
    required String this.firstKeptEntryId,
    required int this.tokensBefore,
    required int this.tokensAfter,
  });

  factory CompactionEntry.fromJson(Map<String, dynamic> json) =>
      _$CompactionEntryFromJson(json);

  final String id;

  final String? parentId;

  final DateTime timestamp;

  final String firstKeptEntryId;

  final int tokensBefore;

  final int tokensAfter;

  CompactionEntry copyWith({
    String? id,
    String? parentId,
    DateTime? timestamp,
    String? firstKeptEntryId,
    int? tokensBefore,
    int? tokensAfter,
  }) {
    return CompactionEntry(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      timestamp: timestamp ?? this.timestamp,
      firstKeptEntryId: firstKeptEntryId ?? this.firstKeptEntryId,
      tokensBefore: tokensBefore ?? this.tokensBefore,
      tokensAfter: tokensAfter ?? this.tokensAfter,
    );
  }

  CompactionEntry copyWithCompactionEntry({
    String? id,
    String? parentId,
    DateTime? timestamp,
    String? firstKeptEntryId,
    int? tokensBefore,
    int? tokensAfter,
  }) {
    return copyWith(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      firstKeptEntryId: firstKeptEntryId,
      tokensBefore: tokensBefore,
      tokensAfter: tokensAfter,
    );
  }

  CompactionEntry patchWithCompactionEntry([CompactionEntryPatch? patchInput]) {
    final _patcher = patchInput ?? CompactionEntryPatch();
    final _patchMap = _patcher.patchMap;
    return CompactionEntry(
      id: _patchMap.containsKey(CompactionEntry$.id)
          ? ((_patchMap[CompactionEntry$.id] is Function)
                    ? _patchMap[CompactionEntry$.id](this.id)
                    : (_patchMap[CompactionEntry$.id] is Patch)
                    ? _patchMap[CompactionEntry$.id].applyTo(this.id)
                    : _patchMap[CompactionEntry$.id])
                as String
          : this.id,
      parentId: _patchMap.containsKey(CompactionEntry$.parentId)
          ? ((_patchMap[CompactionEntry$.parentId] is Function)
                    ? _patchMap[CompactionEntry$.parentId](this.parentId)
                    : (_patchMap[CompactionEntry$.parentId] is Patch)
                    ? _patchMap[CompactionEntry$.parentId].applyTo(
                        this.parentId,
                      )
                    : _patchMap[CompactionEntry$.parentId])
                as String?
          : this.parentId,
      timestamp: _patchMap.containsKey(CompactionEntry$.timestamp)
          ? ((_patchMap[CompactionEntry$.timestamp] is Function)
                    ? _patchMap[CompactionEntry$.timestamp](this.timestamp)
                    : (_patchMap[CompactionEntry$.timestamp] is Patch)
                    ? _patchMap[CompactionEntry$.timestamp].applyTo(
                        this.timestamp,
                      )
                    : _patchMap[CompactionEntry$.timestamp])
                as DateTime
          : this.timestamp,
      firstKeptEntryId: _patchMap.containsKey(CompactionEntry$.firstKeptEntryId)
          ? ((_patchMap[CompactionEntry$.firstKeptEntryId] is Function)
                    ? _patchMap[CompactionEntry$.firstKeptEntryId](
                        this.firstKeptEntryId,
                      )
                    : (_patchMap[CompactionEntry$.firstKeptEntryId] is Patch)
                    ? _patchMap[CompactionEntry$.firstKeptEntryId].applyTo(
                        this.firstKeptEntryId,
                      )
                    : _patchMap[CompactionEntry$.firstKeptEntryId])
                as String
          : this.firstKeptEntryId,
      tokensBefore: _patchMap.containsKey(CompactionEntry$.tokensBefore)
          ? ((_patchMap[CompactionEntry$.tokensBefore] is Function)
                    ? _patchMap[CompactionEntry$.tokensBefore](
                        this.tokensBefore,
                      )
                    : (_patchMap[CompactionEntry$.tokensBefore] is Patch)
                    ? _patchMap[CompactionEntry$.tokensBefore].applyTo(
                        this.tokensBefore,
                      )
                    : _patchMap[CompactionEntry$.tokensBefore])
                as int
          : this.tokensBefore,
      tokensAfter: _patchMap.containsKey(CompactionEntry$.tokensAfter)
          ? ((_patchMap[CompactionEntry$.tokensAfter] is Function)
                    ? _patchMap[CompactionEntry$.tokensAfter](this.tokensAfter)
                    : (_patchMap[CompactionEntry$.tokensAfter] is Patch)
                    ? _patchMap[CompactionEntry$.tokensAfter].applyTo(
                        this.tokensAfter,
                      )
                    : _patchMap[CompactionEntry$.tokensAfter])
                as int
          : this.tokensAfter,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompactionEntry &&
        id == other.id &&
        parentId == other.parentId &&
        timestamp == other.timestamp &&
        firstKeptEntryId == other.firstKeptEntryId &&
        tokensBefore == other.tokensBefore &&
        tokensAfter == other.tokensAfter;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.parentId,
      this.timestamp,
      this.firstKeptEntryId,
      this.tokensBefore,
      this.tokensAfter,
    );
  }

  @override
  String toString() {
    return 'CompactionEntry(' +
        'id: ${id}' +
        ', ' +
        'parentId: ${parentId}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'firstKeptEntryId: ${firstKeptEntryId}' +
        ', ' +
        'tokensBefore: ${tokensBefore}' +
        ', ' +
        'tokensAfter: ${tokensAfter})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CompactionEntryToJson(this);
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

extension CompactionEntryPropertyHelpers on CompactionEntry {
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

  bool get hasFirstKeptEntryId {
    return this.firstKeptEntryId.isNotEmpty;
  }

  bool get noFirstKeptEntryId {
    return this.firstKeptEntryId.isEmpty;
  }
}

extension CompactionEntrySerialization on CompactionEntry {
  Map<String, dynamic> toJson() {
    return _$CompactionEntryToJson(this);
  }
}

enum CompactionEntry$ {
  id,
  parentId,
  timestamp,
  firstKeptEntryId,
  tokensBefore,
  tokensAfter,
}

class CompactionEntryPatch
    extends PatchBase<CompactionEntry, CompactionEntry$> {
  CompactionEntry applyTo(CompactionEntry entity) {
    return entity.patchWithCompactionEntry(this);
  }

  CompactionEntryPatch withId(String? value) {
    patchMap[CompactionEntry$.id] = value;
    return this;
  }

  CompactionEntryPatch withParentId(String? value) {
    patchMap[CompactionEntry$.parentId] = value;
    return this;
  }

  CompactionEntryPatch withTimestamp(DateTime? value) {
    patchMap[CompactionEntry$.timestamp] = value;
    return this;
  }

  CompactionEntryPatch withFirstKeptEntryId(String? value) {
    patchMap[CompactionEntry$.firstKeptEntryId] = value;
    return this;
  }

  CompactionEntryPatch withTokensBefore(int? value) {
    patchMap[CompactionEntry$.tokensBefore] = value;
    return this;
  }

  CompactionEntryPatch withTokensAfter(int? value) {
    patchMap[CompactionEntry$.tokensAfter] = value;
    return this;
  }
}

/// Field descriptors for [CompactionEntry] query construction
abstract final class CompactionEntryFields {
  static const id = Field<CompactionEntry, String>('id', _$id);

  static const parentId = Field<CompactionEntry, String?>(
    'parentId',
    _$parentId,
  );

  static const timestamp = Field<CompactionEntry, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const firstKeptEntryId = Field<CompactionEntry, String>(
    'firstKeptEntryId',
    _$firstKeptEntryId,
  );

  static const tokensBefore = Field<CompactionEntry, int>(
    'tokensBefore',
    _$tokensBefore,
  );

  static const tokensAfter = Field<CompactionEntry, int>(
    'tokensAfter',
    _$tokensAfter,
  );

  static String _$id(CompactionEntry e) {
    return e.id;
  }

  static String? _$parentId(CompactionEntry e) {
    return e.parentId;
  }

  static DateTime _$timestamp(CompactionEntry e) {
    return e.timestamp;
  }

  static String _$firstKeptEntryId(CompactionEntry e) {
    return e.firstKeptEntryId;
  }

  static int _$tokensBefore(CompactionEntry e) {
    return e.tokensBefore;
  }

  static int _$tokensAfter(CompactionEntry e) {
    return e.tokensAfter;
  }
}

extension CompactionEntryCompareE on CompactionEntry {
  Map<String, dynamic> compareToCompactionEntry(CompactionEntry other) {
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

    if (firstKeptEntryId != other.firstKeptEntryId) {
      diff['firstKeptEntryId'] = () => other.firstKeptEntryId;
    }

    if (tokensBefore != other.tokensBefore) {
      diff['tokensBefore'] = () => other.tokensBefore;
    }

    if (tokensAfter != other.tokensAfter) {
      diff['tokensAfter'] = () => other.tokensAfter;
    }
    return diff;
  }
}
