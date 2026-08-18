// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/repositories/turn_record_repository.dart';
import '../../domain/usecases/turn_record/delete_turn_record_usecase.dart';

void registerDeleteTurnRecordUseCase(GetIt getIt) {
  getIt.registerLazySingleton<DeleteTurnRecordUseCase>(
    () => DeleteTurnRecordUseCase(getIt<TurnRecordRepository>()),
  );
}

// END GENERATED
