// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// Concrete provider stub for the FallbackChain data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/fallback_chain/fallback_chain.dart';
import '../../../domain/services/fallback_chain_service.dart';

class FallbackChainProvider
    with Loggable, FailureHandler
    implements FallbackChainService {
  FallbackChainProvider();

  @override
  Future<FallbackChain> current(NoParams params) async =>
      throw UnimplementedError('Implement FallbackChainProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement FallbackChainProvider.count');
}
