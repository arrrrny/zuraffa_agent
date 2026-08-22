// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fallback_chain.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FallbackChain _$FallbackChainFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FallbackChain', json, ($checkedConvert) {
      final val = FallbackChain(
        id: $checkedConvert('id', (v) => v as String?),
        providerOrder: $checkedConvert(
          'providerOrder',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        maxConsecutiveFailures: $checkedConvert(
          'maxConsecutiveFailures',
          (v) => (v as num).toInt(),
        ),
        cooldownMs: $checkedConvert('cooldownMs', (v) => (v as num).toInt()),
        policyMode: $checkedConvert('policyMode', (v) => v as String),
        breakerStates: $checkedConvert(
          'breakerStates',
          (v) => (v as List<dynamic>)
              .map((e) => ClientHealth.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        lastProviderIndex: $checkedConvert(
          'lastProviderIndex',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$FallbackChainToJson(FallbackChain instance) =>
    <String, dynamic>{
      'id': instance.id,
      'providerOrder': instance.providerOrder,
      'maxConsecutiveFailures': instance.maxConsecutiveFailures,
      'cooldownMs': instance.cooldownMs,
      'policyMode': instance.policyMode,
      'breakerStates': instance.breakerStates.map((e) => e.toJson()).toList(),
      'lastProviderIndex': instance.lastProviderIndex,
    };
