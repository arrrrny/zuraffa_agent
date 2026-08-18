// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/repositories/turn_record_repository.dart';
import '../../domain/usecases/turn_record/create_turn_record_usecase.dart';

void registerCreateTurnRecordUseCase(GetIt getIt) {
  getIt.registerLazySingleton<CreateTurnRecordUseCase>(
    () => CreateTurnRecordUseCase(getIt<TurnRecordRepository>()),
  );
}

// END GENERATED
