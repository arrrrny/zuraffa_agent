// GENERATED - DO NOT EDIT
import 'package:zuraffa_flutter/zuraffa_flutter.dart';

import '../../../domain/entities/golden_mission/golden_mission.dart';
import 'golden_mission_presenter.dart';

class GoldenMissionController extends Controller {
  GoldenMissionController(this._presenter);

  final GoldenMissionPresenter _presenter;

  Future<void> getGoldenMission(String id, [CancelToken? cancelToken]) async {
    final result = await _presenter.getGoldenMission(id, cancelToken);
    result.fold((entity) {}, (failure) {});
  }

  Future<void> updateGoldenMission(
    String id,
    GoldenMissionPatch data, [
    CancelToken? cancelToken,
  ]) async {
    final result = await _presenter.updateGoldenMission(id, data, cancelToken);
    result.fold((updated) {}, (failure) {});
  }

  @override
  void onDisposed() {
    _presenter.dispose();
    super.onDisposed();
  }
}

// END GENERATED
