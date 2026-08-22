// GENERATED - DO NOT EDIT
import 'package:zuraffa_flutter/zuraffa_flutter.dart';

import '../../../domain/entities/suite/suite.dart';
import 'suite_presenter.dart';

class SuiteController extends Controller {
  SuiteController(this._presenter);

  final SuitePresenter _presenter;

  Future<void> getSuite(String id, [CancelToken? cancelToken]) async {
    final result = await _presenter.getSuite(id, cancelToken);
    result.fold((entity) {}, (failure) {});
  }

  Future<void> updateSuite(
    String id,
    SuitePatch data, [
    CancelToken? cancelToken,
  ]) async {
    final result = await _presenter.updateSuite(id, data, cancelToken);
    result.fold((updated) {}, (failure) {});
  }

  @override
  void onDisposed() {
    _presenter.dispose();
    super.onDisposed();
  }
}

// END GENERATED
