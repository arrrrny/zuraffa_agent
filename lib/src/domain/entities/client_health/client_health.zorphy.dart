// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'client_health.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class ClientHealth {
  ClientHealth({
    String? id,
    required String this.state,
    required int this.consecutiveFailures,
    required int this.cooldownWindowMs,
    required DateTime this.lastFailureAt,
    required bool this.isHealthy,
  }) : this.id = id ?? const Uuid().v4();

  factory ClientHealth.fromJson(Map<String, dynamic> json) =>
      _$ClientHealthFromJson(json);

  final String id;

  final String state;

  final int consecutiveFailures;

  final int cooldownWindowMs;

  final DateTime lastFailureAt;

  final bool isHealthy;

  ClientHealth copyWith({
    String? id,
    String? state,
    int? consecutiveFailures,
    int? cooldownWindowMs,
    DateTime? lastFailureAt,
    bool? isHealthy,
  }) {
    return ClientHealth(
      id: id ?? this.id,
      state: state ?? this.state,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      cooldownWindowMs: cooldownWindowMs ?? this.cooldownWindowMs,
      lastFailureAt: lastFailureAt ?? this.lastFailureAt,
      isHealthy: isHealthy ?? this.isHealthy,
    );
  }

  ClientHealth copyWithClientHealth({
    String? id,
    String? state,
    int? consecutiveFailures,
    int? cooldownWindowMs,
    DateTime? lastFailureAt,
    bool? isHealthy,
  }) {
    return copyWith(
      id: id,
      state: state,
      consecutiveFailures: consecutiveFailures,
      cooldownWindowMs: cooldownWindowMs,
      lastFailureAt: lastFailureAt,
      isHealthy: isHealthy,
    );
  }

  ClientHealth patchWithClientHealth([ClientHealthPatch? patchInput]) {
    final _patcher = patchInput ?? ClientHealthPatch();
    final _patchMap = _patcher.patchMap;
    return ClientHealth(
      id: _patchMap.containsKey(ClientHealth$.id)
          ? ((_patchMap[ClientHealth$.id] is Function)
                    ? _patchMap[ClientHealth$.id](this.id)
                    : (_patchMap[ClientHealth$.id] is Patch)
                    ? _patchMap[ClientHealth$.id].applyTo(this.id)
                    : _patchMap[ClientHealth$.id])
                as String
          : this.id,
      state: _patchMap.containsKey(ClientHealth$.state)
          ? ((_patchMap[ClientHealth$.state] is Function)
                    ? _patchMap[ClientHealth$.state](this.state)
                    : (_patchMap[ClientHealth$.state] is Patch)
                    ? _patchMap[ClientHealth$.state].applyTo(this.state)
                    : _patchMap[ClientHealth$.state])
                as String
          : this.state,
      consecutiveFailures:
          _patchMap.containsKey(ClientHealth$.consecutiveFailures)
          ? ((_patchMap[ClientHealth$.consecutiveFailures] is Function)
                    ? _patchMap[ClientHealth$.consecutiveFailures](
                        this.consecutiveFailures,
                      )
                    : (_patchMap[ClientHealth$.consecutiveFailures] is Patch)
                    ? _patchMap[ClientHealth$.consecutiveFailures].applyTo(
                        this.consecutiveFailures,
                      )
                    : _patchMap[ClientHealth$.consecutiveFailures])
                as int
          : this.consecutiveFailures,
      cooldownWindowMs: _patchMap.containsKey(ClientHealth$.cooldownWindowMs)
          ? ((_patchMap[ClientHealth$.cooldownWindowMs] is Function)
                    ? _patchMap[ClientHealth$.cooldownWindowMs](
                        this.cooldownWindowMs,
                      )
                    : (_patchMap[ClientHealth$.cooldownWindowMs] is Patch)
                    ? _patchMap[ClientHealth$.cooldownWindowMs].applyTo(
                        this.cooldownWindowMs,
                      )
                    : _patchMap[ClientHealth$.cooldownWindowMs])
                as int
          : this.cooldownWindowMs,
      lastFailureAt: _patchMap.containsKey(ClientHealth$.lastFailureAt)
          ? ((_patchMap[ClientHealth$.lastFailureAt] is Function)
                    ? _patchMap[ClientHealth$.lastFailureAt](this.lastFailureAt)
                    : (_patchMap[ClientHealth$.lastFailureAt] is Patch)
                    ? _patchMap[ClientHealth$.lastFailureAt].applyTo(
                        this.lastFailureAt,
                      )
                    : _patchMap[ClientHealth$.lastFailureAt])
                as DateTime
          : this.lastFailureAt,
      isHealthy: _patchMap.containsKey(ClientHealth$.isHealthy)
          ? ((_patchMap[ClientHealth$.isHealthy] is Function)
                    ? _patchMap[ClientHealth$.isHealthy](this.isHealthy)
                    : (_patchMap[ClientHealth$.isHealthy] is Patch)
                    ? _patchMap[ClientHealth$.isHealthy].applyTo(this.isHealthy)
                    : _patchMap[ClientHealth$.isHealthy])
                as bool
          : this.isHealthy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientHealth &&
        id == other.id &&
        state == other.state &&
        consecutiveFailures == other.consecutiveFailures &&
        cooldownWindowMs == other.cooldownWindowMs &&
        lastFailureAt == other.lastFailureAt &&
        isHealthy == other.isHealthy;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.state,
      this.consecutiveFailures,
      this.cooldownWindowMs,
      this.lastFailureAt,
      this.isHealthy,
    );
  }

  @override
  String toString() {
    return 'ClientHealth(' +
        'id: ${id}' +
        ', ' +
        'state: ${state}' +
        ', ' +
        'consecutiveFailures: ${consecutiveFailures}' +
        ', ' +
        'cooldownWindowMs: ${cooldownWindowMs}' +
        ', ' +
        'lastFailureAt: ${lastFailureAt}' +
        ', ' +
        'isHealthy: ${isHealthy})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ClientHealthToJson(this);
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

extension ClientHealthPropertyHelpers on ClientHealth {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasState {
    return this.state.isNotEmpty;
  }

  bool get noState {
    return this.state.isEmpty;
  }
}

extension ClientHealthSerialization on ClientHealth {
  Map<String, dynamic> toJson() {
    return _$ClientHealthToJson(this);
  }
}

enum ClientHealth$ {
  id,
  state,
  consecutiveFailures,
  cooldownWindowMs,
  lastFailureAt,
  isHealthy,
}

class ClientHealthPatch extends PatchBase<ClientHealth, ClientHealth$> {
  ClientHealth applyTo(ClientHealth entity) {
    return entity.patchWithClientHealth(this);
  }

  ClientHealthPatch withId(String? value) {
    patchMap[ClientHealth$.id] = value;
    return this;
  }

  ClientHealthPatch withState(String? value) {
    patchMap[ClientHealth$.state] = value;
    return this;
  }

  ClientHealthPatch withConsecutiveFailures(int? value) {
    patchMap[ClientHealth$.consecutiveFailures] = value;
    return this;
  }

  ClientHealthPatch withCooldownWindowMs(int? value) {
    patchMap[ClientHealth$.cooldownWindowMs] = value;
    return this;
  }

  ClientHealthPatch withLastFailureAt(DateTime? value) {
    patchMap[ClientHealth$.lastFailureAt] = value;
    return this;
  }

  ClientHealthPatch withIsHealthy(bool? value) {
    patchMap[ClientHealth$.isHealthy] = value;
    return this;
  }
}

/// Field descriptors for [ClientHealth] query construction
abstract final class ClientHealthFields {
  static const id = Field<ClientHealth, String>('id', _$id);

  static const state = Field<ClientHealth, String>('state', _$state);

  static const consecutiveFailures = Field<ClientHealth, int>(
    'consecutiveFailures',
    _$consecutiveFailures,
  );

  static const cooldownWindowMs = Field<ClientHealth, int>(
    'cooldownWindowMs',
    _$cooldownWindowMs,
  );

  static const lastFailureAt = Field<ClientHealth, DateTime>(
    'lastFailureAt',
    _$lastFailureAt,
  );

  static const isHealthy = Field<ClientHealth, bool>('isHealthy', _$isHealthy);

  static String _$id(ClientHealth e) {
    return e.id;
  }

  static String _$state(ClientHealth e) {
    return e.state;
  }

  static int _$consecutiveFailures(ClientHealth e) {
    return e.consecutiveFailures;
  }

  static int _$cooldownWindowMs(ClientHealth e) {
    return e.cooldownWindowMs;
  }

  static DateTime _$lastFailureAt(ClientHealth e) {
    return e.lastFailureAt;
  }

  static bool _$isHealthy(ClientHealth e) {
    return e.isHealthy;
  }
}

extension ClientHealthCompareE on ClientHealth {
  Map<String, dynamic> compareToClientHealth(ClientHealth other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (state != other.state) {
      diff['state'] = () => other.state;
    }

    if (consecutiveFailures != other.consecutiveFailures) {
      diff['consecutiveFailures'] = () => other.consecutiveFailures;
    }

    if (cooldownWindowMs != other.cooldownWindowMs) {
      diff['cooldownWindowMs'] = () => other.cooldownWindowMs;
    }

    if (lastFailureAt != other.lastFailureAt) {
      diff['lastFailureAt'] = () => other.lastFailureAt;
    }

    if (isHealthy != other.isHealthy) {
      diff['isHealthy'] = () => other.isHealthy;
    }
    return diff;
  }
}
