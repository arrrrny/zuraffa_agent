// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// Concrete provider for the ProviderConfig data layer. Returns the active
// provider configuration (Constitution: config-driven, not hard-coded). This
// replaces the previous UnimplementedError stub (spec 052).
//
// spec 106 (issue #117): fail closed — there is NO default provider. An
// explicit configuration must be injected; absence is a construction-time
// error, never a silent route to a third-party gateway at first turn.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/provider_config/provider_config.dart';
import '../../../domain/services/provider_config_service.dart';

class ProviderConfigProvider
    with Loggable, FailureHandler
    implements ProviderConfigService {
  final ProviderConfig _active;

  ProviderConfigProvider([ProviderConfig? active]) : _active = _require(active);

  static ProviderConfig _require(ProviderConfig? active) {
    if (active == null) {
      throw ArgumentError.value(
        active,
        'config',
        'ProviderConfigProvider requires an injected ProviderConfig — '
        'no default is provided (issue #117)',
      );
    }
    return active;
  }

  @override
  Future<ProviderConfig> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
