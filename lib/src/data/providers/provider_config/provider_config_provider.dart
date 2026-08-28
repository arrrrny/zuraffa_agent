// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// Concrete provider for the ProviderConfig data layer. Returns the active
// provider configuration (Constitution: config-driven, not hard-coded). This
// replaces the previous UnimplementedError stub (spec 052).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/provider_config/provider_config.dart';
import '../../../domain/services/provider_config_service.dart';

class ProviderConfigProvider
    with Loggable, FailureHandler
    implements ProviderConfigService {
  final ProviderConfig _active;

  ProviderConfigProvider([ProviderConfig? active])
      : _active = active ??
            const ProviderConfig(
              id: 'kilo',
              providerKind: 'openai',
              baseUrl: 'https://api.kilo.ai/api/gateway',
              models: ['tencent/hy3:free'],
              timeoutMs: 30000,
            );

  @override
  Future<ProviderConfig> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
