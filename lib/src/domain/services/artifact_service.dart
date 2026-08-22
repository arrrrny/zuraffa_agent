// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../entities/store_params/store_params.dart';
import '../entities/artifact_store_result/artifact_store_result.dart';
import '../entities/artifact_ref/artifact_ref.dart';
import '../entities/artifact/artifact.dart';

/// Service interface for ArtifactService
abstract class ArtifactService {
  Future<ArtifactStoreResult> store(StoreParams params);

  Future<Artifact?> fetch(ArtifactRef params);

  Future<void> delete(ArtifactRef params);

  Future<List<ArtifactRef>> list();

  int thresholdBytes();
}

// END GENERATED
