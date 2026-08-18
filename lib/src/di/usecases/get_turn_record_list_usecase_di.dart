// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/repositories/turn_record_repository.dart';
import '../../domain/usecases/turn_record/get_turn_record_list_usecase.dart';

void registerGetTurnRecordListUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetTurnRecordListUseCase>(
    () => GetTurnRecordListUseCase(getIt<TurnRecordRepository>()),
  );
}

// END GENERATED
