// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/repositories/tool_invocation_record_repository.dart';
import '../../domain/usecases/tool_invocation_record/get_tool_invocation_record_list_usecase.dart';

void registerGetToolInvocationRecordListUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetToolInvocationRecordListUseCase>(
    () => GetToolInvocationRecordListUseCase(
      getIt<ToolInvocationRecordRepository>(),
    ),
  );
}

// END GENERATED
