// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'fallback_chain.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class FallbackChain {
  FallbackChain({
    String? id,
    required List<String> this.providerOrder,
    required int this.maxConsecutiveFailures,
    required int this.cooldownMs,
    required String this.policyMode,
    required List<ClientHealth> this.breakerStates,
    required int this.lastProviderIndex,
  }) : this.id = id ?? const Uuid().v4();

  factory FallbackChain.fromJson(Map<String, dynamic> json) =>
      _$FallbackChainFromJson(json);

  final String id;

  final List<String> providerOrder;

  final int maxConsecutiveFailures;

  final int cooldownMs;

  final String policyMode;

  final List<ClientHealth> breakerStates;

  final int lastProviderIndex;

  FallbackChain copyWith({
    String? id,
    List<String>? providerOrder,
    int? maxConsecutiveFailures,
    int? cooldownMs,
    String? policyMode,
    List<ClientHealth>? breakerStates,
    int? lastProviderIndex,
  }) {
    return FallbackChain(
      id: id ?? this.id,
      providerOrder: providerOrder ?? this.providerOrder,
      maxConsecutiveFailures:
          maxConsecutiveFailures ?? this.maxConsecutiveFailures,
      cooldownMs: cooldownMs ?? this.cooldownMs,
      policyMode: policyMode ?? this.policyMode,
      breakerStates: breakerStates ?? this.breakerStates,
      lastProviderIndex: lastProviderIndex ?? this.lastProviderIndex,
    );
  }

  FallbackChain copyWithFallbackChain({
    String? id,
    List<String>? providerOrder,
    int? maxConsecutiveFailures,
    int? cooldownMs,
    String? policyMode,
    List<ClientHealth>? breakerStates,
    int? lastProviderIndex,
  }) {
    return copyWith(
      id: id,
      providerOrder: providerOrder,
      maxConsecutiveFailures: maxConsecutiveFailures,
      cooldownMs: cooldownMs,
      policyMode: policyMode,
      breakerStates: breakerStates,
      lastProviderIndex: lastProviderIndex,
    );
  }

  FallbackChain patchWithFallbackChain([FallbackChainPatch? patchInput]) {
    final _patcher = patchInput ?? FallbackChainPatch();
    final _patchMap = _patcher.patchMap;
    return FallbackChain(
      id: _patchMap.containsKey(FallbackChain$.id)
          ? ((_patchMap[FallbackChain$.id] is Function)
                    ? _patchMap[FallbackChain$.id](this.id)
                    : (_patchMap[FallbackChain$.id] is Patch)
                    ? _patchMap[FallbackChain$.id].applyTo(this.id)
                    : _patchMap[FallbackChain$.id])
                as String
          : this.id,
      providerOrder: _patchMap.containsKey(FallbackChain$.providerOrder)
          ? ((_patchMap[FallbackChain$.providerOrder] is Function)
                    ? _patchMap[FallbackChain$.providerOrder](
                        this.providerOrder,
                      )
                    : (_patchMap[FallbackChain$.providerOrder] is Patch)
                    ? _patchMap[FallbackChain$.providerOrder].applyTo(
                        this.providerOrder,
                      )
                    : _patchMap[FallbackChain$.providerOrder])
                as List<String>
          : this.providerOrder,
      maxConsecutiveFailures:
          _patchMap.containsKey(FallbackChain$.maxConsecutiveFailures)
          ? ((_patchMap[FallbackChain$.maxConsecutiveFailures] is Function)
                    ? _patchMap[FallbackChain$.maxConsecutiveFailures](
                        this.maxConsecutiveFailures,
                      )
                    : (_patchMap[FallbackChain$.maxConsecutiveFailures]
                          is Patch)
                    ? _patchMap[FallbackChain$.maxConsecutiveFailures].applyTo(
                        this.maxConsecutiveFailures,
                      )
                    : _patchMap[FallbackChain$.maxConsecutiveFailures])
                as int
          : this.maxConsecutiveFailures,
      cooldownMs: _patchMap.containsKey(FallbackChain$.cooldownMs)
          ? ((_patchMap[FallbackChain$.cooldownMs] is Function)
                    ? _patchMap[FallbackChain$.cooldownMs](this.cooldownMs)
                    : (_patchMap[FallbackChain$.cooldownMs] is Patch)
                    ? _patchMap[FallbackChain$.cooldownMs].applyTo(
                        this.cooldownMs,
                      )
                    : _patchMap[FallbackChain$.cooldownMs])
                as int
          : this.cooldownMs,
      policyMode: _patchMap.containsKey(FallbackChain$.policyMode)
          ? ((_patchMap[FallbackChain$.policyMode] is Function)
                    ? _patchMap[FallbackChain$.policyMode](this.policyMode)
                    : (_patchMap[FallbackChain$.policyMode] is Patch)
                    ? _patchMap[FallbackChain$.policyMode].applyTo(
                        this.policyMode,
                      )
                    : _patchMap[FallbackChain$.policyMode])
                as String
          : this.policyMode,
      breakerStates: _patchMap.containsKey(FallbackChain$.breakerStates)
          ? ((_patchMap[FallbackChain$.breakerStates] is Function)
                    ? _patchMap[FallbackChain$.breakerStates](
                        this.breakerStates,
                      )
                    : (_patchMap[FallbackChain$.breakerStates] is Patch)
                    ? _patchMap[FallbackChain$.breakerStates].applyTo(
                        this.breakerStates,
                      )
                    : _patchMap[FallbackChain$.breakerStates])
                as List<ClientHealth>
          : this.breakerStates,
      lastProviderIndex: _patchMap.containsKey(FallbackChain$.lastProviderIndex)
          ? ((_patchMap[FallbackChain$.lastProviderIndex] is Function)
                    ? _patchMap[FallbackChain$.lastProviderIndex](
                        this.lastProviderIndex,
                      )
                    : (_patchMap[FallbackChain$.lastProviderIndex] is Patch)
                    ? _patchMap[FallbackChain$.lastProviderIndex].applyTo(
                        this.lastProviderIndex,
                      )
                    : _patchMap[FallbackChain$.lastProviderIndex])
                as int
          : this.lastProviderIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FallbackChain &&
        id == other.id &&
        providerOrder == other.providerOrder &&
        maxConsecutiveFailures == other.maxConsecutiveFailures &&
        cooldownMs == other.cooldownMs &&
        policyMode == other.policyMode &&
        breakerStates == other.breakerStates &&
        lastProviderIndex == other.lastProviderIndex;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.providerOrder,
      this.maxConsecutiveFailures,
      this.cooldownMs,
      this.policyMode,
      this.breakerStates,
      this.lastProviderIndex,
    );
  }

  @override
  String toString() {
    return 'FallbackChain(' +
        'id: ${id}' +
        ', ' +
        'providerOrder: ${providerOrder}' +
        ', ' +
        'maxConsecutiveFailures: ${maxConsecutiveFailures}' +
        ', ' +
        'cooldownMs: ${cooldownMs}' +
        ', ' +
        'policyMode: ${policyMode}' +
        ', ' +
        'breakerStates: ${breakerStates}' +
        ', ' +
        'lastProviderIndex: ${lastProviderIndex})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$FallbackChainToJson(this);
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

extension FallbackChainPropertyHelpers on FallbackChain {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasProviderOrder {
    return this.providerOrder.isNotEmpty;
  }

  bool get noProviderOrder {
    return this.providerOrder.isEmpty;
  }

  bool get hasPolicyMode {
    return this.policyMode.isNotEmpty;
  }

  bool get noPolicyMode {
    return this.policyMode.isEmpty;
  }

  bool get hasBreakerStates {
    return this.breakerStates.isNotEmpty;
  }

  bool get noBreakerStates {
    return this.breakerStates.isEmpty;
  }
}

extension FallbackChainSerialization on FallbackChain {
  Map<String, dynamic> toJson() {
    return _$FallbackChainToJson(this);
  }
}

enum FallbackChain$ {
  id,
  providerOrder,
  maxConsecutiveFailures,
  cooldownMs,
  policyMode,
  breakerStates,
  lastProviderIndex,
}

class FallbackChainPatch extends PatchBase<FallbackChain, FallbackChain$> {
  FallbackChain applyTo(FallbackChain entity) {
    return entity.patchWithFallbackChain(this);
  }

  FallbackChainPatch withId(String? value) {
    patchMap[FallbackChain$.id] = value;
    return this;
  }

  FallbackChainPatch withProviderOrder(List<String>? value) {
    patchMap[FallbackChain$.providerOrder] = value;
    return this;
  }

  FallbackChainPatch withMaxConsecutiveFailures(int? value) {
    patchMap[FallbackChain$.maxConsecutiveFailures] = value;
    return this;
  }

  FallbackChainPatch withCooldownMs(int? value) {
    patchMap[FallbackChain$.cooldownMs] = value;
    return this;
  }

  FallbackChainPatch withPolicyMode(String? value) {
    patchMap[FallbackChain$.policyMode] = value;
    return this;
  }

  FallbackChainPatch withBreakerStates(List<ClientHealth>? value) {
    patchMap[FallbackChain$.breakerStates] = value;
    return this;
  }

  FallbackChainPatch updateBreakerStatesAt(
    int index,
    ClientHealthPatch Function(ClientHealthPatch) patch,
  ) {
    patchMap[FallbackChain$.breakerStates] = (List<dynamic> list) {
      var updatedList = List<ClientHealth>.from(list);
      if (index >= 0 && index < updatedList.length) {
        updatedList[index] = patch(
          ClientHealthPatch(),
        ).applyTo(updatedList[index] as ClientHealth);
      }
      return updatedList;
    };
    return this;
  }

  FallbackChainPatch withLastProviderIndex(int? value) {
    patchMap[FallbackChain$.lastProviderIndex] = value;
    return this;
  }
}

/// Field descriptors for [FallbackChain] query construction
abstract final class FallbackChainFields {
  static const id = Field<FallbackChain, String>('id', _$id);

  static const providerOrder = Field<FallbackChain, List<String>>(
    'providerOrder',
    _$providerOrder,
  );

  static const maxConsecutiveFailures = Field<FallbackChain, int>(
    'maxConsecutiveFailures',
    _$maxConsecutiveFailures,
  );

  static const cooldownMs = Field<FallbackChain, int>(
    'cooldownMs',
    _$cooldownMs,
  );

  static const policyMode = Field<FallbackChain, String>(
    'policyMode',
    _$policyMode,
  );

  static const breakerStates = Field<FallbackChain, List<ClientHealth>>(
    'breakerStates',
    _$breakerStates,
  );

  static const lastProviderIndex = Field<FallbackChain, int>(
    'lastProviderIndex',
    _$lastProviderIndex,
  );

  static String _$id(FallbackChain e) {
    return e.id;
  }

  static List<String> _$providerOrder(FallbackChain e) {
    return e.providerOrder;
  }

  static int _$maxConsecutiveFailures(FallbackChain e) {
    return e.maxConsecutiveFailures;
  }

  static int _$cooldownMs(FallbackChain e) {
    return e.cooldownMs;
  }

  static String _$policyMode(FallbackChain e) {
    return e.policyMode;
  }

  static List<ClientHealth> _$breakerStates(FallbackChain e) {
    return e.breakerStates;
  }

  static int _$lastProviderIndex(FallbackChain e) {
    return e.lastProviderIndex;
  }
}

extension FallbackChainCompareE on FallbackChain {
  Map<String, dynamic> compareToFallbackChain(FallbackChain other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (providerOrder != other.providerOrder) {
      diff['providerOrder'] = () => other.providerOrder;
    }

    if (maxConsecutiveFailures != other.maxConsecutiveFailures) {
      diff['maxConsecutiveFailures'] = () => other.maxConsecutiveFailures;
    }

    if (cooldownMs != other.cooldownMs) {
      diff['cooldownMs'] = () => other.cooldownMs;
    }

    if (policyMode != other.policyMode) {
      diff['policyMode'] = () => other.policyMode;
    }

    if (breakerStates != other.breakerStates) {
      diff['breakerStates'] = () => other.breakerStates;
    }

    if (lastProviderIndex != other.lastProviderIndex) {
      diff['lastProviderIndex'] = () => other.lastProviderIndex;
    }
    return diff;
  }
}
