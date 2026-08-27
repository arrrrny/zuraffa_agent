// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#8 (UI/tree+json payloads).
//
// Concrete provider for the UiTreePayload data layer. Returns the most
// recently emitted ui/tree+json payload in the active mission as a
// constructed default (spec 052).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/ui_tree_payload/ui_tree_payload.dart';
import '../../../domain/services/ui_tree_payload_service.dart';

class UiTreePayloadProvider
    with Loggable, FailureHandler
    implements UiTreePayloadService {
  static const Map<String, dynamic> _kDefaultTree = <String, dynamic>{
    'type': 'root',
    'children': <Map<String, dynamic>>[
      <String, dynamic>{'type': 'panel'},
    ],
  };

  final UiTreePayload _active;

  UiTreePayloadProvider([UiTreePayload? active])
      : _active = active ??
            UiTreePayload(
              vocabularyId: 'shadcn-ui@1.0.0',
              schemaVersion: '1.0.0',
              tree: _kDefaultTree,
            );

  @override
  Future<UiTreePayload> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
