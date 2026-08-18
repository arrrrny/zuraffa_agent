// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../data/datasources/turn_record/turn_record_remote_datasource.dart';
import '../../data/repositories/data_turn_record_repository.dart';
import '../../domain/repositories/turn_record_repository.dart';

void registerTurnRecordRepository(GetIt getIt) {
  getIt.registerLazySingleton<TurnRecordRepository>(
    () => DataTurnRecordRepository(getIt<TurnRecordRemoteDataSource>()),
  );
}

// END GENERATED
