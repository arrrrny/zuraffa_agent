// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/artifact/artifact.dart';

abstract class ArtifactDataSource with Loggable, FailureHandler {
  Future<Artifact> get(QueryParams<Artifact> params);
  Future<Artifact> update(UpdateParams<String, ArtifactPatch> params);
  Future<Artifact> toggle(
    ToggleParams<String, Field<Artifact, dynamic>> params,
  );
}

// END GENERATED
