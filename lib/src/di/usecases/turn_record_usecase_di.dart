// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/turn_record/get_turn_record_usecase.dart';
import '../../domain/usecases/turn_record/get_turn_record_list_usecase.dart';
import '../../domain/usecases/turn_record/create_turn_record_usecase.dart';
import '../../domain/usecases/turn_record/update_turn_record_usecase.dart';
import '../../domain/usecases/turn_record/delete_turn_record_usecase.dart';

void registerTurnRecordUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetTurnRecordUseCase>(() => GetTurnRecordUseCase(getIt()));
  getIt.registerLazySingleton<GetTurnRecordListUseCase>(() => GetTurnRecordListUseCase(getIt()));
  getIt.registerLazySingleton<CreateTurnRecordUseCase>(() => CreateTurnRecordUseCase(getIt()));
  getIt.registerLazySingleton<UpdateTurnRecordUseCase>(() => UpdateTurnRecordUseCase(getIt()));
  getIt.registerLazySingleton<DeleteTurnRecordUseCase>(() => DeleteTurnRecordUseCase(getIt()));
}

// END GENERATED
