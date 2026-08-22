// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/artifact/artifact.dart';
import '../../../domain/entities/artifact_ref/artifact_ref.dart';
import '../../../domain/entities/artifact_store_result/artifact_store_result.dart';
import '../../../domain/entities/store_params/store_params.dart';
import '../../../domain/services/artifact_service.dart';

class ArtifactProvider
    with Loggable, FailureHandler
    implements ArtifactService {
  @override
  Future<ArtifactStoreResult> store(StoreParams params) async {
    final error = UnimplementedError('store not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }

  @override
  Future<Artifact?> fetch(ArtifactRef params) async {
    final error = UnimplementedError('fetch not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }

  @override
  Future<void> delete(ArtifactRef params) async {
    final error = UnimplementedError('delete not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }

  @override
  Future<List<ArtifactRef>> list() async {
    final error = UnimplementedError('list not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }

  @override
  int thresholdBytes() {
    final error = UnimplementedError('thresholdBytes not implemented');
    final stack = StackTrace.current;
    logAndHandleError(error, stack);
    throw error;
  }
}

// END GENERATED
