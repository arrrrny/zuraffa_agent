// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// Concrete provider stub for the ProviderConfig data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/provider_config/provider_config.dart';
import '../../../domain/services/provider_config_service.dart';

class ProviderConfigProvider
    with Loggable, FailureHandler
    implements ProviderConfigService {
  ProviderConfigProvider();

  @override
  Future<ProviderConfig> current(NoParams params) async =>
      throw UnimplementedError('Implement ProviderConfigProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement ProviderConfigProvider.count');
}
