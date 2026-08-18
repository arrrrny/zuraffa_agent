// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/repositories/tool_invocation_record_repository.dart';
import '../../domain/usecases/tool_invocation_record/delete_tool_invocation_record_usecase.dart';

void registerDeleteToolInvocationRecordUseCase(GetIt getIt) {
  getIt.registerLazySingleton<DeleteToolInvocationRecordUseCase>(
    () => DeleteToolInvocationRecordUseCase(
      getIt<ToolInvocationRecordRepository>(),
    ),
  );
}

// END GENERATED
