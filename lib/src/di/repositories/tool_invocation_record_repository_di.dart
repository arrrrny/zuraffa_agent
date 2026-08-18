// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../data/datasources/tool_invocation_record/tool_invocation_record_remote_datasource.dart';
import '../../data/repositories/data_tool_invocation_record_repository.dart';
import '../../domain/repositories/tool_invocation_record_repository.dart';

void registerToolInvocationRecordRepository(GetIt getIt) {
  getIt.registerLazySingleton<ToolInvocationRecordRepository>(
    () => DataToolInvocationRecordRepository(
      getIt<ToolInvocationRecordRemoteDataSource>(),
    ),
  );
}

// END GENERATED
