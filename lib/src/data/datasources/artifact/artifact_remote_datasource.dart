// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/artifact/artifact.dart';
import 'artifact_datasource.dart';

class ArtifactRemoteDataSource
    with Loggable, FailureHandler
    implements ArtifactDataSource {
  @override
  Future<Artifact> get(QueryParams<Artifact> params) async {
    throw UnimplementedError('Implement remote get');
  }

  @override
  Future<Artifact> update(UpdateParams<String, ArtifactPatch> params) async {
    throw UnimplementedError('Implement remote update');
  }

  @override
  Future<Artifact> toggle(
    ToggleParams<String, Field<Artifact, dynamic>> params,
  ) async {
    throw UnimplementedError('Implement remote toggle');
  }
}

// END GENERATED
