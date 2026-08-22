// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'golden_mission.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class GoldenMission {
  GoldenMission({
    required String this.id,
    required String this.name,
    Map<String, dynamic>? this.cassette,
    required String this.taskDefinition,
    List<String>? this.graderBindings,
  });

  factory GoldenMission.fromJson(Map<String, dynamic> json) =>
      _$GoldenMissionFromJson(json);

  final String id;

  final String name;

  final Map<String, dynamic>? cassette;

  final String taskDefinition;

  final List<String>? graderBindings;

  GoldenMission copyWith({
    String? id,
    String? name,
    Map<String, dynamic>? cassette,
    String? taskDefinition,
    List<String>? graderBindings,
  }) {
    return GoldenMission(
      id: id ?? this.id,
      name: name ?? this.name,
      cassette: cassette ?? this.cassette,
      taskDefinition: taskDefinition ?? this.taskDefinition,
      graderBindings: graderBindings ?? this.graderBindings,
    );
  }

  GoldenMission copyWithGoldenMission({
    String? id,
    String? name,
    Map<String, dynamic>? cassette,
    String? taskDefinition,
    List<String>? graderBindings,
  }) {
    return copyWith(
      id: id,
      name: name,
      cassette: cassette,
      taskDefinition: taskDefinition,
      graderBindings: graderBindings,
    );
  }

  GoldenMission patchWithGoldenMission([GoldenMissionPatch? patchInput]) {
    final _patcher = patchInput ?? GoldenMissionPatch();
    final _patchMap = _patcher.patchMap;
    return GoldenMission(
      id: _patchMap.containsKey(GoldenMission$.id)
          ? ((_patchMap[GoldenMission$.id] is Function)
                    ? _patchMap[GoldenMission$.id](this.id)
                    : (_patchMap[GoldenMission$.id] is Patch)
                    ? _patchMap[GoldenMission$.id].applyTo(this.id)
                    : _patchMap[GoldenMission$.id])
                as String
          : this.id,
      name: _patchMap.containsKey(GoldenMission$.name_)
          ? ((_patchMap[GoldenMission$.name_] is Function)
                    ? _patchMap[GoldenMission$.name_](this.name)
                    : (_patchMap[GoldenMission$.name_] is Patch)
                    ? _patchMap[GoldenMission$.name_].applyTo(this.name)
                    : _patchMap[GoldenMission$.name_])
                as String
          : this.name,
      cassette: _patchMap.containsKey(GoldenMission$.cassette)
          ? ((_patchMap[GoldenMission$.cassette] is Function)
                    ? _patchMap[GoldenMission$.cassette](this.cassette)
                    : (_patchMap[GoldenMission$.cassette] is Patch)
                    ? _patchMap[GoldenMission$.cassette].applyTo(this.cassette)
                    : _patchMap[GoldenMission$.cassette])
                as Map<String, dynamic>?
          : this.cassette,
      taskDefinition: _patchMap.containsKey(GoldenMission$.taskDefinition)
          ? ((_patchMap[GoldenMission$.taskDefinition] is Function)
                    ? _patchMap[GoldenMission$.taskDefinition](
                        this.taskDefinition,
                      )
                    : (_patchMap[GoldenMission$.taskDefinition] is Patch)
                    ? _patchMap[GoldenMission$.taskDefinition].applyTo(
                        this.taskDefinition,
                      )
                    : _patchMap[GoldenMission$.taskDefinition])
                as String
          : this.taskDefinition,
      graderBindings: _patchMap.containsKey(GoldenMission$.graderBindings)
          ? ((_patchMap[GoldenMission$.graderBindings] is Function)
                    ? _patchMap[GoldenMission$.graderBindings](
                        this.graderBindings,
                      )
                    : (_patchMap[GoldenMission$.graderBindings] is Patch)
                    ? _patchMap[GoldenMission$.graderBindings].applyTo(
                        this.graderBindings,
                      )
                    : _patchMap[GoldenMission$.graderBindings])
                as List<String>?
          : this.graderBindings,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoldenMission &&
        id == other.id &&
        name == other.name &&
        cassette == other.cassette &&
        taskDefinition == other.taskDefinition &&
        graderBindings == other.graderBindings;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.name,
      this.cassette,
      this.taskDefinition,
      this.graderBindings,
    );
  }

  @override
  String toString() {
    return 'GoldenMission(' +
        'id: ${id}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'cassette: ${cassette}' +
        ', ' +
        'taskDefinition: ${taskDefinition}' +
        ', ' +
        'graderBindings: ${graderBindings})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$GoldenMissionToJson(this);
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

extension GoldenMissionPropertyHelpers on GoldenMission {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasName {
    return this.name.isNotEmpty;
  }

  bool get noName {
    return this.name.isEmpty;
  }

  Map<String, dynamic> get cassetteRequired {
    return this.cassette ??
        (throw StateError('cassette is required but was null'));
  }

  bool get hasCassette {
    return this.cassette?.isNotEmpty ?? false;
  }

  bool get noCassette {
    return this.cassette?.isEmpty ?? true;
  }

  bool get hasTaskDefinition {
    return this.taskDefinition.isNotEmpty;
  }

  bool get noTaskDefinition {
    return this.taskDefinition.isEmpty;
  }

  List<String> get graderBindingsRequired {
    return this.graderBindings ??
        (throw StateError('graderBindings is required but was null'));
  }

  bool get hasGraderBindings {
    return this.graderBindings?.isNotEmpty ?? false;
  }

  bool get noGraderBindings {
    return this.graderBindings?.isEmpty ?? true;
  }
}

extension GoldenMissionSerialization on GoldenMission {
  Map<String, dynamic> toJson() {
    return _$GoldenMissionToJson(this);
  }
}

enum GoldenMission$ { id, name_, cassette, taskDefinition, graderBindings }

class GoldenMissionPatch extends PatchBase<GoldenMission, GoldenMission$> {
  GoldenMission applyTo(GoldenMission entity) {
    return entity.patchWithGoldenMission(this);
  }

  GoldenMissionPatch withId(String? value) {
    patchMap[GoldenMission$.id] = value;
    return this;
  }

  GoldenMissionPatch withName(String? value) {
    patchMap[GoldenMission$.name_] = value;
    return this;
  }

  GoldenMissionPatch withCassette(Map<String, dynamic>? value) {
    patchMap[GoldenMission$.cassette] = value;
    return this;
  }

  GoldenMissionPatch withTaskDefinition(String? value) {
    patchMap[GoldenMission$.taskDefinition] = value;
    return this;
  }

  GoldenMissionPatch withGraderBindings(List<String>? value) {
    patchMap[GoldenMission$.graderBindings] = value;
    return this;
  }
}

/// Field descriptors for [GoldenMission] query construction
abstract final class GoldenMissionFields {
  static const id = Field<GoldenMission, String>('id', _$id);

  static const name = Field<GoldenMission, String>('name', _$name);

  static const cassette = Field<GoldenMission, Map<String, dynamic>?>(
    'cassette',
    _$cassette,
  );

  static const taskDefinition = Field<GoldenMission, String>(
    'taskDefinition',
    _$taskDefinition,
  );

  static const graderBindings = Field<GoldenMission, List<String>?>(
    'graderBindings',
    _$graderBindings,
  );

  static String _$id(GoldenMission e) {
    return e.id;
  }

  static String _$name(GoldenMission e) {
    return e.name;
  }

  static Map<String, dynamic>? _$cassette(GoldenMission e) {
    return e.cassette;
  }

  static String _$taskDefinition(GoldenMission e) {
    return e.taskDefinition;
  }

  static List<String>? _$graderBindings(GoldenMission e) {
    return e.graderBindings;
  }
}

extension GoldenMissionCompareE on GoldenMission {
  Map<String, dynamic> compareToGoldenMission(GoldenMission other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (name != other.name) {
      diff['name'] = () => other.name;
    }

    if (cassette != other.cassette) {
      diff['cassette'] = () => other.cassette;
    }

    if (taskDefinition != other.taskDefinition) {
      diff['taskDefinition'] = () => other.taskDefinition;
    }

    if (graderBindings != other.graderBindings) {
      diff['graderBindings'] = () => other.graderBindings;
    }
    return diff;
  }
}
