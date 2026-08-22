// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/artifact_ref/artifact_ref.dart';

abstract class ArtifactRefDataSource with Loggable, FailureHandler {
  Future<ArtifactRef> get(QueryParams<ArtifactRef> params);
  Future<ArtifactRef> update(UpdateParams<String, ArtifactRefPatch> params);
  Future<ArtifactRef> toggle(
    ToggleParams<String, Field<ArtifactRef, dynamic>> params,
  );
}

// END GENERATED
