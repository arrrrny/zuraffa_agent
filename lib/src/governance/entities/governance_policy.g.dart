// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'governance_policy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GovernancePolicy _$GovernancePolicyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GovernancePolicy', json, ($checkedConvert) {
      final val = GovernancePolicy(
        id: $checkedConvert('id', (v) => v as String),
        toolAllowList: $checkedConvert(
          'toolAllowList',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        toolDenyList: $checkedConvert(
          'toolDenyList',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        riskTiers: $checkedConvert(
          'riskTiers',
          (v) => (v as Map<String, dynamic>).map(
            (k, e) => MapEntry(k, $enumDecode(_$RiskTierEnumMap, e)),
          ),
        ),
        redactionRules: $checkedConvert(
          'redactionRules',
          (v) => (v as List<dynamic>)
              .map((e) => RedactionRule.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        requireApprovalForTiers: $checkedConvert(
          'requireApprovalForTiers',
          (v) => (v as List<dynamic>)
              .map((e) => $enumDecode(_$RiskTierEnumMap, e))
              .toList(),
        ),
        oversizedResultThreshold: $checkedConvert(
          'oversizedResultThreshold',
          (v) => (v as num?)?.toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GovernancePolicyToJson(GovernancePolicy instance) =>
    <String, dynamic>{
      'id': instance.id,
      'toolAllowList': instance.toolAllowList,
      'toolDenyList': instance.toolDenyList,
      'riskTiers': instance.riskTiers.map(
        (k, e) => MapEntry(k, _$RiskTierEnumMap[e]!),
      ),
      'redactionRules': instance.redactionRules.map((e) => e.toJson()).toList(),
      'requireApprovalForTiers': instance.requireApprovalForTiers
          .map((e) => _$RiskTierEnumMap[e]!)
          .toList(),
      'oversizedResultThreshold': ?instance.oversizedResultThreshold,
    };

const _$RiskTierEnumMap = {
  RiskTier.low: 'low',
  RiskTier.medium: 'medium',
  RiskTier.high: 'high',
  RiskTier.critical: 'critical',
};
