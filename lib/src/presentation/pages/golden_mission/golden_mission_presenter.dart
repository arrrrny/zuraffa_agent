// GENERATED - DO NOT EDIT
import 'package:zuraffa_flutter/zuraffa_flutter.dart';

import '../../../domain/entities/golden_mission/golden_mission.dart';
import '../../../domain/repositories/golden_mission_repository.dart';
import '../../../domain/usecases/golden_mission/get_golden_mission_usecase.dart';
import '../../../domain/usecases/golden_mission/update_golden_mission_usecase.dart';

class GoldenMissionPresenter extends Presenter {
  GoldenMissionPresenter({required this.goldenMissionRepository}) {
    _getGoldenMission = registerUseCase(
      GetGoldenMissionUseCase(goldenMissionRepository),
    );
    _updateGoldenMission = registerUseCase(
      UpdateGoldenMissionUseCase(goldenMissionRepository),
    );
  }

  final GoldenMissionRepository goldenMissionRepository;

  late final GetGoldenMissionUseCase _getGoldenMission;

  late final UpdateGoldenMissionUseCase _updateGoldenMission;

  Future<Result<GoldenMission, AppFailure>> getGoldenMission(
    String id, [
    CancelToken? cancelToken,
  ]) {
    return _getGoldenMission.call(
      QueryParams<GoldenMission>(filter: Eq(GoldenMissionFields.id, id)),
      cancelToken: cancelToken,
    );
  }

  Future<Result<GoldenMission, AppFailure>> updateGoldenMission(
    String id,
    GoldenMissionPatch data, [
    CancelToken? cancelToken,
  ]) {
    return _updateGoldenMission.call(
      UpdateParams<String, GoldenMissionPatch>(id: id, data: data),
      cancelToken: cancelToken,
    );
  }
}

// END GENERATED
