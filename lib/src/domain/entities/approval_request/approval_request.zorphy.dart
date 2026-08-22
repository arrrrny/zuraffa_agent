// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'approval_request.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class ApprovalRequest {
  ApprovalRequest({
    required String this.toolName,
    required Map<String, dynamic> this.arguments,
    required DateTime this.requestedAt,
    required int this.timeoutMs,
    required String this.id,
  });

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) =>
      _$ApprovalRequestFromJson(json);

  final String toolName;

  final Map<String, dynamic> arguments;

  final DateTime requestedAt;

  final int timeoutMs;

  final String id;

  ApprovalRequest copyWith({
    String? toolName,
    Map<String, dynamic>? arguments,
    DateTime? requestedAt,
    int? timeoutMs,
    String? id,
  }) {
    return ApprovalRequest(
      toolName: toolName ?? this.toolName,
      arguments: arguments ?? this.arguments,
      requestedAt: requestedAt ?? this.requestedAt,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      id: id ?? this.id,
    );
  }

  ApprovalRequest copyWithApprovalRequest({
    String? toolName,
    Map<String, dynamic>? arguments,
    DateTime? requestedAt,
    int? timeoutMs,
    String? id,
  }) {
    return copyWith(
      toolName: toolName,
      arguments: arguments,
      requestedAt: requestedAt,
      timeoutMs: timeoutMs,
      id: id,
    );
  }

  ApprovalRequest patchWithApprovalRequest([ApprovalRequestPatch? patchInput]) {
    final _patcher = patchInput ?? ApprovalRequestPatch();
    final _patchMap = _patcher.patchMap;
    return ApprovalRequest(
      toolName: _patchMap.containsKey(ApprovalRequest$.toolName)
          ? ((_patchMap[ApprovalRequest$.toolName] is Function)
                    ? _patchMap[ApprovalRequest$.toolName](this.toolName)
                    : (_patchMap[ApprovalRequest$.toolName] is Patch)
                    ? _patchMap[ApprovalRequest$.toolName].applyTo(
                        this.toolName,
                      )
                    : _patchMap[ApprovalRequest$.toolName])
                as String
          : this.toolName,
      arguments: _patchMap.containsKey(ApprovalRequest$.arguments)
          ? ((_patchMap[ApprovalRequest$.arguments] is Function)
                    ? _patchMap[ApprovalRequest$.arguments](this.arguments)
                    : (_patchMap[ApprovalRequest$.arguments] is Patch)
                    ? _patchMap[ApprovalRequest$.arguments].applyTo(
                        this.arguments,
                      )
                    : _patchMap[ApprovalRequest$.arguments])
                as Map<String, dynamic>
          : this.arguments,
      requestedAt: _patchMap.containsKey(ApprovalRequest$.requestedAt)
          ? ((_patchMap[ApprovalRequest$.requestedAt] is Function)
                    ? _patchMap[ApprovalRequest$.requestedAt](this.requestedAt)
                    : (_patchMap[ApprovalRequest$.requestedAt] is Patch)
                    ? _patchMap[ApprovalRequest$.requestedAt].applyTo(
                        this.requestedAt,
                      )
                    : _patchMap[ApprovalRequest$.requestedAt])
                as DateTime
          : this.requestedAt,
      timeoutMs: _patchMap.containsKey(ApprovalRequest$.timeoutMs)
          ? ((_patchMap[ApprovalRequest$.timeoutMs] is Function)
                    ? _patchMap[ApprovalRequest$.timeoutMs](this.timeoutMs)
                    : (_patchMap[ApprovalRequest$.timeoutMs] is Patch)
                    ? _patchMap[ApprovalRequest$.timeoutMs].applyTo(
                        this.timeoutMs,
                      )
                    : _patchMap[ApprovalRequest$.timeoutMs])
                as int
          : this.timeoutMs,
      id: _patchMap.containsKey(ApprovalRequest$.id)
          ? ((_patchMap[ApprovalRequest$.id] is Function)
                    ? _patchMap[ApprovalRequest$.id](this.id)
                    : (_patchMap[ApprovalRequest$.id] is Patch)
                    ? _patchMap[ApprovalRequest$.id].applyTo(this.id)
                    : _patchMap[ApprovalRequest$.id])
                as String
          : this.id,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApprovalRequest &&
        toolName == other.toolName &&
        arguments == other.arguments &&
        requestedAt == other.requestedAt &&
        timeoutMs == other.timeoutMs &&
        id == other.id;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.toolName,
      this.arguments,
      this.requestedAt,
      this.timeoutMs,
      this.id,
    );
  }

  @override
  String toString() {
    return 'ApprovalRequest(' +
        'toolName: ${toolName}' +
        ', ' +
        'arguments: ${arguments}' +
        ', ' +
        'requestedAt: ${requestedAt}' +
        ', ' +
        'timeoutMs: ${timeoutMs}' +
        ', ' +
        'id: ${id})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ApprovalRequestToJson(this);
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

extension ApprovalRequestPropertyHelpers on ApprovalRequest {
  bool get hasToolName {
    return this.toolName.isNotEmpty;
  }

  bool get noToolName {
    return this.toolName.isEmpty;
  }

  bool get hasArguments {
    return this.arguments.isNotEmpty;
  }

  bool get noArguments {
    return this.arguments.isEmpty;
  }

  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }
}

extension ApprovalRequestSerialization on ApprovalRequest {
  Map<String, dynamic> toJson() {
    return _$ApprovalRequestToJson(this);
  }
}

enum ApprovalRequest$ { toolName, arguments, requestedAt, timeoutMs, id }

class ApprovalRequestPatch
    extends PatchBase<ApprovalRequest, ApprovalRequest$> {
  ApprovalRequest applyTo(ApprovalRequest entity) {
    return entity.patchWithApprovalRequest(this);
  }

  ApprovalRequestPatch withToolName(String? value) {
    patchMap[ApprovalRequest$.toolName] = value;
    return this;
  }

  ApprovalRequestPatch withArguments(Map<String, dynamic>? value) {
    patchMap[ApprovalRequest$.arguments] = value;
    return this;
  }

  ApprovalRequestPatch withRequestedAt(DateTime? value) {
    patchMap[ApprovalRequest$.requestedAt] = value;
    return this;
  }

  ApprovalRequestPatch withTimeoutMs(int? value) {
    patchMap[ApprovalRequest$.timeoutMs] = value;
    return this;
  }

  ApprovalRequestPatch withId(String? value) {
    patchMap[ApprovalRequest$.id] = value;
    return this;
  }
}

/// Field descriptors for [ApprovalRequest] query construction
abstract final class ApprovalRequestFields {
  static const toolName = Field<ApprovalRequest, String>(
    'toolName',
    _$toolName,
  );

  static const arguments = Field<ApprovalRequest, Map<String, dynamic>>(
    'arguments',
    _$arguments,
  );

  static const requestedAt = Field<ApprovalRequest, DateTime>(
    'requestedAt',
    _$requestedAt,
  );

  static const timeoutMs = Field<ApprovalRequest, int>(
    'timeoutMs',
    _$timeoutMs,
  );

  static const id = Field<ApprovalRequest, String>('id', _$id);

  static String _$toolName(ApprovalRequest e) {
    return e.toolName;
  }

  static Map<String, dynamic> _$arguments(ApprovalRequest e) {
    return e.arguments;
  }

  static DateTime _$requestedAt(ApprovalRequest e) {
    return e.requestedAt;
  }

  static int _$timeoutMs(ApprovalRequest e) {
    return e.timeoutMs;
  }

  static String _$id(ApprovalRequest e) {
    return e.id;
  }
}

extension ApprovalRequestCompareE on ApprovalRequest {
  Map<String, dynamic> compareToApprovalRequest(ApprovalRequest other) {
    final Map<String, dynamic> diff = {};

    if (toolName != other.toolName) {
      diff['toolName'] = () => other.toolName;
    }

    if (arguments != other.arguments) {
      diff['arguments'] = () => other.arguments;
    }

    if (requestedAt != other.requestedAt) {
      diff['requestedAt'] = () => other.requestedAt;
    }

    if (timeoutMs != other.timeoutMs) {
      diff['timeoutMs'] = () => other.timeoutMs;
    }

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    return diff;
  }
}
