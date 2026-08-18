// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/repositories/tool_invocation_record_repository.dart';
import '../../domain/usecases/tool_invocation_record/create_tool_invocation_record_usecase.dart';

void registerCreateToolInvocationRecordUseCase(GetIt getIt) {
  getIt.registerLazySingleton<CreateToolInvocationRecordUseCase>(
    () => CreateToolInvocationRecordUseCase(
      getIt<ToolInvocationRecordRepository>(),
    ),
  );
}

// END GENERATED
