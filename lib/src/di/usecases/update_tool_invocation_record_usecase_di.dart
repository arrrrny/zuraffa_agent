// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/repositories/tool_invocation_record_repository.dart';
import '../../domain/usecases/tool_invocation_record/update_tool_invocation_record_usecase.dart';

void registerUpdateToolInvocationRecordUseCase(GetIt getIt) {
  getIt.registerLazySingleton<UpdateToolInvocationRecordUseCase>(
    () => UpdateToolInvocationRecordUseCase(
      getIt<ToolInvocationRecordRepository>(),
    ),
  );
}

// END GENERATED
