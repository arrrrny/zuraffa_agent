// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/repositories/turn_record_repository.dart';
import '../../domain/usecases/turn_record/update_turn_record_usecase.dart';

void registerUpdateTurnRecordUseCase(GetIt getIt) {
  getIt.registerLazySingleton<UpdateTurnRecordUseCase>(
    () => UpdateTurnRecordUseCase(getIt<TurnRecordRepository>()),
  );
}

// END GENERATED
