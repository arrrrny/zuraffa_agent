// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/artifact_ref/artifact_ref.dart';
import 'artifact_ref_datasource.dart';

class ArtifactRefRemoteDataSource
    with Loggable, FailureHandler
    implements ArtifactRefDataSource {
  @override
  Future<ArtifactRef> get(QueryParams<ArtifactRef> params) async {
    throw UnimplementedError('Implement remote get');
  }

  @override
  Future<ArtifactRef> update(
    UpdateParams<String, ArtifactRefPatch> params,
  ) async {
    throw UnimplementedError('Implement remote update');
  }

  @override
  Future<ArtifactRef> toggle(
    ToggleParams<String, Field<ArtifactRef, dynamic>> params,
  ) async {
    throw UnimplementedError('Implement remote toggle');
  }
}

// END GENERATED
