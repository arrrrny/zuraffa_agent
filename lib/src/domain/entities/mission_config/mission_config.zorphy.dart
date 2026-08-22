// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'mission_config.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class MissionConfig {
  MissionConfig({
    String? id,
    required String this.missionId,
    required String this.initialPrompt,
    required List<String> this.availableTools,
    required Map<String, dynamic> this.metadata,
  }) : this.id = id ?? const Uuid().v4();

  factory MissionConfig.fromJson(Map<String, dynamic> json) =>
      _$MissionConfigFromJson(json);

  final String id;

  final String missionId;

  final String initialPrompt;

  final List<String> availableTools;

  final Map<String, dynamic> metadata;

  MissionConfig copyWith({
    String? id,
    String? missionId,
    String? initialPrompt,
    List<String>? availableTools,
    Map<String, dynamic>? metadata,
  }) {
    return MissionConfig(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      initialPrompt: initialPrompt ?? this.initialPrompt,
      availableTools: availableTools ?? this.availableTools,
      metadata: metadata ?? this.metadata,
    );
  }

  MissionConfig copyWithMissionConfig({
    String? id,
    String? missionId,
    String? initialPrompt,
    List<String>? availableTools,
    Map<String, dynamic>? metadata,
  }) {
    return copyWith(
      id: id,
      missionId: missionId,
      initialPrompt: initialPrompt,
      availableTools: availableTools,
      metadata: metadata,
    );
  }

  MissionConfig patchWithMissionConfig([MissionConfigPatch? patchInput]) {
    final _patcher = patchInput ?? MissionConfigPatch();
    final _patchMap = _patcher.patchMap;
    return MissionConfig(
      id: _patchMap.containsKey(MissionConfig$.id)
          ? ((_patchMap[MissionConfig$.id] is Function)
                    ? _patchMap[MissionConfig$.id](this.id)
                    : (_patchMap[MissionConfig$.id] is Patch)
                    ? _patchMap[MissionConfig$.id].applyTo(this.id)
                    : _patchMap[MissionConfig$.id])
                as String
          : this.id,
      missionId: _patchMap.containsKey(MissionConfig$.missionId)
          ? ((_patchMap[MissionConfig$.missionId] is Function)
                    ? _patchMap[MissionConfig$.missionId](this.missionId)
                    : (_patchMap[MissionConfig$.missionId] is Patch)
                    ? _patchMap[MissionConfig$.missionId].applyTo(
                        this.missionId,
                      )
                    : _patchMap[MissionConfig$.missionId])
                as String
          : this.missionId,
      initialPrompt: _patchMap.containsKey(MissionConfig$.initialPrompt)
          ? ((_patchMap[MissionConfig$.initialPrompt] is Function)
                    ? _patchMap[MissionConfig$.initialPrompt](
                        this.initialPrompt,
                      )
                    : (_patchMap[MissionConfig$.initialPrompt] is Patch)
                    ? _patchMap[MissionConfig$.initialPrompt].applyTo(
                        this.initialPrompt,
                      )
                    : _patchMap[MissionConfig$.initialPrompt])
                as String
          : this.initialPrompt,
      availableTools: _patchMap.containsKey(MissionConfig$.availableTools)
          ? ((_patchMap[MissionConfig$.availableTools] is Function)
                    ? _patchMap[MissionConfig$.availableTools](
                        this.availableTools,
                      )
                    : (_patchMap[MissionConfig$.availableTools] is Patch)
                    ? _patchMap[MissionConfig$.availableTools].applyTo(
                        this.availableTools,
                      )
                    : _patchMap[MissionConfig$.availableTools])
                as List<String>
          : this.availableTools,
      metadata: _patchMap.containsKey(MissionConfig$.metadata)
          ? ((_patchMap[MissionConfig$.metadata] is Function)
                    ? _patchMap[MissionConfig$.metadata](this.metadata)
                    : (_patchMap[MissionConfig$.metadata] is Patch)
                    ? _patchMap[MissionConfig$.metadata].applyTo(this.metadata)
                    : _patchMap[MissionConfig$.metadata])
                as Map<String, dynamic>
          : this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MissionConfig &&
        id == other.id &&
        missionId == other.missionId &&
        initialPrompt == other.initialPrompt &&
        availableTools == other.availableTools &&
        metadata == other.metadata;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.missionId,
      this.initialPrompt,
      this.availableTools,
      this.metadata,
    );
  }

  @override
  String toString() {
    return 'MissionConfig(' +
        'id: ${id}' +
        ', ' +
        'missionId: ${missionId}' +
        ', ' +
        'initialPrompt: ${initialPrompt}' +
        ', ' +
        'availableTools: ${availableTools}' +
        ', ' +
        'metadata: ${metadata})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$MissionConfigToJson(this);
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

extension MissionConfigPropertyHelpers on MissionConfig {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasMissionId {
    return this.missionId.isNotEmpty;
  }

  bool get noMissionId {
    return this.missionId.isEmpty;
  }

  bool get hasInitialPrompt {
    return this.initialPrompt.isNotEmpty;
  }

  bool get noInitialPrompt {
    return this.initialPrompt.isEmpty;
  }

  bool get hasAvailableTools {
    return this.availableTools.isNotEmpty;
  }

  bool get noAvailableTools {
    return this.availableTools.isEmpty;
  }

  bool get hasMetadata {
    return this.metadata.isNotEmpty;
  }

  bool get noMetadata {
    return this.metadata.isEmpty;
  }
}

extension MissionConfigSerialization on MissionConfig {
  Map<String, dynamic> toJson() {
    return _$MissionConfigToJson(this);
  }
}

enum MissionConfig$ { id, missionId, initialPrompt, availableTools, metadata }

class MissionConfigPatch extends PatchBase<MissionConfig, MissionConfig$> {
  MissionConfig applyTo(MissionConfig entity) {
    return entity.patchWithMissionConfig(this);
  }

  MissionConfigPatch withId(String? value) {
    patchMap[MissionConfig$.id] = value;
    return this;
  }

  MissionConfigPatch withMissionId(String? value) {
    patchMap[MissionConfig$.missionId] = value;
    return this;
  }

  MissionConfigPatch withInitialPrompt(String? value) {
    patchMap[MissionConfig$.initialPrompt] = value;
    return this;
  }

  MissionConfigPatch withAvailableTools(List<String>? value) {
    patchMap[MissionConfig$.availableTools] = value;
    return this;
  }

  MissionConfigPatch withMetadata(Map<String, dynamic>? value) {
    patchMap[MissionConfig$.metadata] = value;
    return this;
  }
}

/// Field descriptors for [MissionConfig] query construction
abstract final class MissionConfigFields {
  static const id = Field<MissionConfig, String>('id', _$id);

  static const missionId = Field<MissionConfig, String>(
    'missionId',
    _$missionId,
  );

  static const initialPrompt = Field<MissionConfig, String>(
    'initialPrompt',
    _$initialPrompt,
  );

  static const availableTools = Field<MissionConfig, List<String>>(
    'availableTools',
    _$availableTools,
  );

  static const metadata = Field<MissionConfig, Map<String, dynamic>>(
    'metadata',
    _$metadata,
  );

  static String _$id(MissionConfig e) {
    return e.id;
  }

  static String _$missionId(MissionConfig e) {
    return e.missionId;
  }

  static String _$initialPrompt(MissionConfig e) {
    return e.initialPrompt;
  }

  static List<String> _$availableTools(MissionConfig e) {
    return e.availableTools;
  }

  static Map<String, dynamic> _$metadata(MissionConfig e) {
    return e.metadata;
  }
}

extension MissionConfigCompareE on MissionConfig {
  Map<String, dynamic> compareToMissionConfig(MissionConfig other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (missionId != other.missionId) {
      diff['missionId'] = () => other.missionId;
    }

    if (initialPrompt != other.initialPrompt) {
      diff['initialPrompt'] = () => other.initialPrompt;
    }

    if (availableTools != other.availableTools) {
      diff['availableTools'] = () => other.availableTools;
    }

    if (metadata != other.metadata) {
      diff['metadata'] = () => other.metadata;
    }
    return diff;
  }
}
