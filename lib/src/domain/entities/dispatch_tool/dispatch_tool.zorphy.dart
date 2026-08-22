// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'dispatch_tool.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class DispatchTool {
  DispatchTool({
    required String this.id,
    required String this.type,
    required String this.task,
    required String this.instanceId,
    required String this.lifecycle,
  });

  factory DispatchTool.fromJson(Map<String, dynamic> json) =>
      _$DispatchToolFromJson(json);

  final String id;

  final String type;

  final String task;

  final String instanceId;

  final String lifecycle;

  DispatchTool copyWith({
    String? id,
    String? type,
    String? task,
    String? instanceId,
    String? lifecycle,
  }) {
    return DispatchTool(
      id: id ?? this.id,
      type: type ?? this.type,
      task: task ?? this.task,
      instanceId: instanceId ?? this.instanceId,
      lifecycle: lifecycle ?? this.lifecycle,
    );
  }

  DispatchTool copyWithDispatchTool({
    String? id,
    String? type,
    String? task,
    String? instanceId,
    String? lifecycle,
  }) {
    return copyWith(
      id: id,
      type: type,
      task: task,
      instanceId: instanceId,
      lifecycle: lifecycle,
    );
  }

  DispatchTool patchWithDispatchTool([DispatchToolPatch? patchInput]) {
    final _patcher = patchInput ?? DispatchToolPatch();
    final _patchMap = _patcher.patchMap;
    return DispatchTool(
      id: _patchMap.containsKey(DispatchTool$.id)
          ? ((_patchMap[DispatchTool$.id] is Function)
                    ? _patchMap[DispatchTool$.id](this.id)
                    : (_patchMap[DispatchTool$.id] is Patch)
                    ? _patchMap[DispatchTool$.id].applyTo(this.id)
                    : _patchMap[DispatchTool$.id])
                as String
          : this.id,
      type: _patchMap.containsKey(DispatchTool$.type)
          ? ((_patchMap[DispatchTool$.type] is Function)
                    ? _patchMap[DispatchTool$.type](this.type)
                    : (_patchMap[DispatchTool$.type] is Patch)
                    ? _patchMap[DispatchTool$.type].applyTo(this.type)
                    : _patchMap[DispatchTool$.type])
                as String
          : this.type,
      task: _patchMap.containsKey(DispatchTool$.task)
          ? ((_patchMap[DispatchTool$.task] is Function)
                    ? _patchMap[DispatchTool$.task](this.task)
                    : (_patchMap[DispatchTool$.task] is Patch)
                    ? _patchMap[DispatchTool$.task].applyTo(this.task)
                    : _patchMap[DispatchTool$.task])
                as String
          : this.task,
      instanceId: _patchMap.containsKey(DispatchTool$.instanceId)
          ? ((_patchMap[DispatchTool$.instanceId] is Function)
                    ? _patchMap[DispatchTool$.instanceId](this.instanceId)
                    : (_patchMap[DispatchTool$.instanceId] is Patch)
                    ? _patchMap[DispatchTool$.instanceId].applyTo(
                        this.instanceId,
                      )
                    : _patchMap[DispatchTool$.instanceId])
                as String
          : this.instanceId,
      lifecycle: _patchMap.containsKey(DispatchTool$.lifecycle)
          ? ((_patchMap[DispatchTool$.lifecycle] is Function)
                    ? _patchMap[DispatchTool$.lifecycle](this.lifecycle)
                    : (_patchMap[DispatchTool$.lifecycle] is Patch)
                    ? _patchMap[DispatchTool$.lifecycle].applyTo(this.lifecycle)
                    : _patchMap[DispatchTool$.lifecycle])
                as String
          : this.lifecycle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DispatchTool &&
        id == other.id &&
        type == other.type &&
        task == other.task &&
        instanceId == other.instanceId &&
        lifecycle == other.lifecycle;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.type,
      this.task,
      this.instanceId,
      this.lifecycle,
    );
  }

  @override
  String toString() {
    return 'DispatchTool(' +
        'id: ${id}' +
        ', ' +
        'type: ${type}' +
        ', ' +
        'task: ${task}' +
        ', ' +
        'instanceId: ${instanceId}' +
        ', ' +
        'lifecycle: ${lifecycle})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$DispatchToolToJson(this);
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

extension DispatchToolPropertyHelpers on DispatchTool {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasType {
    return this.type.isNotEmpty;
  }

  bool get noType {
    return this.type.isEmpty;
  }

  bool get hasTask {
    return this.task.isNotEmpty;
  }

  bool get noTask {
    return this.task.isEmpty;
  }

  bool get hasInstanceId {
    return this.instanceId.isNotEmpty;
  }

  bool get noInstanceId {
    return this.instanceId.isEmpty;
  }

  bool get hasLifecycle {
    return this.lifecycle.isNotEmpty;
  }

  bool get noLifecycle {
    return this.lifecycle.isEmpty;
  }
}

extension DispatchToolSerialization on DispatchTool {
  Map<String, dynamic> toJson() {
    return _$DispatchToolToJson(this);
  }
}

enum DispatchTool$ { id, type, task, instanceId, lifecycle }

class DispatchToolPatch extends PatchBase<DispatchTool, DispatchTool$> {
  DispatchTool applyTo(DispatchTool entity) {
    return entity.patchWithDispatchTool(this);
  }

  DispatchToolPatch withId(String? value) {
    patchMap[DispatchTool$.id] = value;
    return this;
  }

  DispatchToolPatch withType(String? value) {
    patchMap[DispatchTool$.type] = value;
    return this;
  }

  DispatchToolPatch withTask(String? value) {
    patchMap[DispatchTool$.task] = value;
    return this;
  }

  DispatchToolPatch withInstanceId(String? value) {
    patchMap[DispatchTool$.instanceId] = value;
    return this;
  }

  DispatchToolPatch withLifecycle(String? value) {
    patchMap[DispatchTool$.lifecycle] = value;
    return this;
  }
}

/// Field descriptors for [DispatchTool] query construction
abstract final class DispatchToolFields {
  static const id = Field<DispatchTool, String>('id', _$id);

  static const type = Field<DispatchTool, String>('type', _$type);

  static const task = Field<DispatchTool, String>('task', _$task);

  static const instanceId = Field<DispatchTool, String>(
    'instanceId',
    _$instanceId,
  );

  static const lifecycle = Field<DispatchTool, String>(
    'lifecycle',
    _$lifecycle,
  );

  static String _$id(DispatchTool e) {
    return e.id;
  }

  static String _$type(DispatchTool e) {
    return e.type;
  }

  static String _$task(DispatchTool e) {
    return e.task;
  }

  static String _$instanceId(DispatchTool e) {
    return e.instanceId;
  }

  static String _$lifecycle(DispatchTool e) {
    return e.lifecycle;
  }
}

extension DispatchToolCompareE on DispatchTool {
  Map<String, dynamic> compareToDispatchTool(DispatchTool other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (type != other.type) {
      diff['type'] = () => other.type;
    }

    if (task != other.task) {
      diff['task'] = () => other.task;
    }

    if (instanceId != other.instanceId) {
      diff['instanceId'] = () => other.instanceId;
    }

    if (lifecycle != other.lifecycle) {
      diff['lifecycle'] = () => other.lifecycle;
    }
    return diff;
  }
}
