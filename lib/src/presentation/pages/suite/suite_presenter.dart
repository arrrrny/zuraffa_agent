// GENERATED - DO NOT EDIT
import 'package:zuraffa_flutter/zuraffa_flutter.dart';

import '../../../domain/entities/suite/suite.dart';
import '../../../domain/repositories/suite_repository.dart';
import '../../../domain/usecases/suite/get_suite_usecase.dart';
import '../../../domain/usecases/suite/update_suite_usecase.dart';

class SuitePresenter extends Presenter {
  SuitePresenter({required this.suiteRepository}) {
    _getSuite = registerUseCase(GetSuiteUseCase(suiteRepository));
    _updateSuite = registerUseCase(UpdateSuiteUseCase(suiteRepository));
  }

  final SuiteRepository suiteRepository;

  late final GetSuiteUseCase _getSuite;

  late final UpdateSuiteUseCase _updateSuite;

  Future<Result<Suite, AppFailure>> getSuite(
    String id, [
    CancelToken? cancelToken,
  ]) {
    return _getSuite.call(
      QueryParams<Suite>(filter: Eq(SuiteFields.id, id)),
      cancelToken: cancelToken,
    );
  }

  Future<Result<Suite, AppFailure>> updateSuite(
    String id,
    SuitePatch data, [
    CancelToken? cancelToken,
  ]) {
    return _updateSuite.call(
      UpdateParams<String, SuitePatch>(id: id, data: data),
      cancelToken: cancelToken,
    );
  }
}

// END GENERATED
