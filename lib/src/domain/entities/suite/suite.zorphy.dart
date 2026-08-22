// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'suite.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class Suite {
  Suite({
    required String this.id,
    required String this.name,
    required List<String> this.tasks,
    required int this.k,
    double? this.gateThreshold,
  });

  factory Suite.fromJson(Map<String, dynamic> json) => _$SuiteFromJson(json);

  final String id;

  final String name;

  final List<String> tasks;

  final int k;

  final double? gateThreshold;

  Suite copyWith({
    String? id,
    String? name,
    List<String>? tasks,
    int? k,
    double? gateThreshold,
  }) {
    return Suite(
      id: id ?? this.id,
      name: name ?? this.name,
      tasks: tasks ?? this.tasks,
      k: k ?? this.k,
      gateThreshold: gateThreshold ?? this.gateThreshold,
    );
  }

  Suite copyWithSuite({
    String? id,
    String? name,
    List<String>? tasks,
    int? k,
    double? gateThreshold,
  }) {
    return copyWith(
      id: id,
      name: name,
      tasks: tasks,
      k: k,
      gateThreshold: gateThreshold,
    );
  }

  Suite patchWithSuite([SuitePatch? patchInput]) {
    final _patcher = patchInput ?? SuitePatch();
    final _patchMap = _patcher.patchMap;
    return Suite(
      id: _patchMap.containsKey(Suite$.id)
          ? ((_patchMap[Suite$.id] is Function)
                    ? _patchMap[Suite$.id](this.id)
                    : (_patchMap[Suite$.id] is Patch)
                    ? _patchMap[Suite$.id].applyTo(this.id)
                    : _patchMap[Suite$.id])
                as String
          : this.id,
      name: _patchMap.containsKey(Suite$.name_)
          ? ((_patchMap[Suite$.name_] is Function)
                    ? _patchMap[Suite$.name_](this.name)
                    : (_patchMap[Suite$.name_] is Patch)
                    ? _patchMap[Suite$.name_].applyTo(this.name)
                    : _patchMap[Suite$.name_])
                as String
          : this.name,
      tasks: _patchMap.containsKey(Suite$.tasks)
          ? ((_patchMap[Suite$.tasks] is Function)
                    ? _patchMap[Suite$.tasks](this.tasks)
                    : (_patchMap[Suite$.tasks] is Patch)
                    ? _patchMap[Suite$.tasks].applyTo(this.tasks)
                    : _patchMap[Suite$.tasks])
                as List<String>
          : this.tasks,
      k: _patchMap.containsKey(Suite$.k)
          ? ((_patchMap[Suite$.k] is Function)
                    ? _patchMap[Suite$.k](this.k)
                    : (_patchMap[Suite$.k] is Patch)
                    ? _patchMap[Suite$.k].applyTo(this.k)
                    : _patchMap[Suite$.k])
                as int
          : this.k,
      gateThreshold: _patchMap.containsKey(Suite$.gateThreshold)
          ? ((_patchMap[Suite$.gateThreshold] is Function)
                    ? _patchMap[Suite$.gateThreshold](this.gateThreshold)
                    : (_patchMap[Suite$.gateThreshold] is Patch)
                    ? _patchMap[Suite$.gateThreshold].applyTo(
                        this.gateThreshold,
                      )
                    : _patchMap[Suite$.gateThreshold])
                as double?
          : this.gateThreshold,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Suite &&
        id == other.id &&
        name == other.name &&
        tasks == other.tasks &&
        k == other.k &&
        gateThreshold == other.gateThreshold;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.name,
      this.tasks,
      this.k,
      this.gateThreshold,
    );
  }

  @override
  String toString() {
    return 'Suite(' +
        'id: ${id}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'tasks: ${tasks}' +
        ', ' +
        'k: ${k}' +
        ', ' +
        'gateThreshold: ${gateThreshold})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$SuiteToJson(this);
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

extension SuitePropertyHelpers on Suite {
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

  bool get hasTasks {
    return this.tasks.isNotEmpty;
  }

  bool get noTasks {
    return this.tasks.isEmpty;
  }

  bool get hasGateThreshold {
    return this.gateThreshold != null;
  }

  bool get noGateThreshold {
    return this.gateThreshold == null;
  }

  double get gateThresholdRequired {
    return this.gateThreshold ??
        (throw StateError('gateThreshold is required but was null'));
  }
}

extension SuiteSerialization on Suite {
  Map<String, dynamic> toJson() {
    return _$SuiteToJson(this);
  }
}

enum Suite$ { id, name_, tasks, k, gateThreshold }

class SuitePatch extends PatchBase<Suite, Suite$> {
  Suite applyTo(Suite entity) {
    return entity.patchWithSuite(this);
  }

  SuitePatch withId(String? value) {
    patchMap[Suite$.id] = value;
    return this;
  }

  SuitePatch withName(String? value) {
    patchMap[Suite$.name_] = value;
    return this;
  }

  SuitePatch withTasks(List<String>? value) {
    patchMap[Suite$.tasks] = value;
    return this;
  }

  SuitePatch withK(int? value) {
    patchMap[Suite$.k] = value;
    return this;
  }

  SuitePatch withGateThreshold(double? value) {
    patchMap[Suite$.gateThreshold] = value;
    return this;
  }
}

/// Field descriptors for [Suite] query construction
abstract final class SuiteFields {
  static const id = Field<Suite, String>('id', _$id);

  static const name = Field<Suite, String>('name', _$name);

  static const tasks = Field<Suite, List<String>>('tasks', _$tasks);

  static const k = Field<Suite, int>('k', _$k);

  static const gateThreshold = Field<Suite, double?>(
    'gateThreshold',
    _$gateThreshold,
  );

  static String _$id(Suite e) {
    return e.id;
  }

  static String _$name(Suite e) {
    return e.name;
  }

  static List<String> _$tasks(Suite e) {
    return e.tasks;
  }

  static int _$k(Suite e) {
    return e.k;
  }

  static double? _$gateThreshold(Suite e) {
    return e.gateThreshold;
  }
}

extension SuiteCompareE on Suite {
  Map<String, dynamic> compareToSuite(Suite other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (name != other.name) {
      diff['name'] = () => other.name;
    }

    if (tasks != other.tasks) {
      diff['tasks'] = () => other.tasks;
    }

    if (k != other.k) {
      diff['k'] = () => other.k;
    }

    if (gateThreshold != other.gateThreshold) {
      diff['gateThreshold'] = () => other.gateThreshold;
    }
    return diff;
  }
}
