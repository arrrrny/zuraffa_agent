// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#11.
//
// Mirrors the zfa-generated stub convention (see
// `lib/src/data/datasources/turn_record/turn_record_remote_datasource.dart`
// for the reference shape: `class X with Loggable, FailureHandler implements Y`,
// bodies `throw UnimplementedError('Implement remote ...')`).
//
// The header intentionally does NOT say `// GENERATED - DO NOT EDIT` — this
// file was written by hand and is the canonical source until zfa ships a
// consistent ArtifactProvider/ArtifactService pair.

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/artifact_ref/artifact_ref.dart';
import '../../../domain/services/artifact_service.dart';

/// Stub provider for the artifact data layer.
///
/// Bodies throw `UnimplementedError` on purpose: the parameter exists solely
/// to satisfy the `@override` contract on `ArtifactService`. Real I/O is
/// added by the consuming application when it wires a concrete store.
class ArtifactProvider with Loggable, FailureHandler implements ArtifactService {
  ArtifactProvider();

  @override
  Future<List<ArtifactRef>> list(NoParams params) async =>
      throw UnimplementedError('Implement ArtifactProvider.list');

  @override
  int thresholdBytes(NoParams params) =>
      throw UnimplementedError('Implement ArtifactProvider.thresholdBytes');
}
