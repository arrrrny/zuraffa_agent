// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// Concrete provider for the FallbackChain data layer. Returns the current
// fallback chain snapshot (ordered provider chain, current index, advance
// history). This replaces the previous throwing stub (spec 033).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/fallback_chain/fallback_chain.dart';
import '../../../domain/services/fallback_chain_service.dart';

class FallbackChainProvider
    with Loggable, FailureHandler
    implements FallbackChainService {
  final FallbackChain _active;

  FallbackChainProvider([FallbackChain? active])
      : _active = active ??
            FallbackChain(
              id: 'default',
              providerIds: ['kilo', 'anthropic', 'gemini'],
              currentProviderIndex: 0,
              advances: 0,
            );

  @override
  Future<FallbackChain> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
