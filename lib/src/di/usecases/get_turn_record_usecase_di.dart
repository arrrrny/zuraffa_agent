// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/repositories/turn_record_repository.dart';
import '../../domain/usecases/turn_record/get_turn_record_usecase.dart';

void registerGetTurnRecordUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetTurnRecordUseCase>(
    () => GetTurnRecordUseCase(getIt<TurnRecordRepository>()),
  );
}

// END GENERATED
