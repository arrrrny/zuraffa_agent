// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/repositories/tool_invocation_record_repository.dart';
import '../../domain/usecases/tool_invocation_record/get_tool_invocation_record_usecase.dart';

void registerGetToolInvocationRecordUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetToolInvocationRecordUseCase>(
    () =>
        GetToolInvocationRecordUseCase(getIt<ToolInvocationRecordRepository>()),
  );
}

// END GENERATED
