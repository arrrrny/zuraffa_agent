// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/tool_invocation_record/create_tool_invocation_record_usecase.dart';
import '../../domain/usecases/tool_invocation_record/get_tool_invocation_record_usecase.dart';
import '../../domain/usecases/tool_invocation_record/delete_tool_invocation_record_usecase.dart';
import '../../domain/usecases/tool_invocation_record/get_tool_invocation_record_list_usecase.dart';
import '../../domain/usecases/tool_invocation_record/update_tool_invocation_record_usecase.dart';

void registerToolInvocationRecordUseCase(GetIt getIt) {
  getIt.registerLazySingleton<CreateToolInvocationRecordUseCase>(() => CreateToolInvocationRecordUseCase(getIt()));
  getIt.registerLazySingleton<GetToolInvocationRecordUseCase>(() => GetToolInvocationRecordUseCase(getIt()));
  getIt.registerLazySingleton<DeleteToolInvocationRecordUseCase>(() => DeleteToolInvocationRecordUseCase(getIt()));
  getIt.registerLazySingleton<GetToolInvocationRecordListUseCase>(() => GetToolInvocationRecordListUseCase(getIt()));
  getIt.registerLazySingleton<UpdateToolInvocationRecordUseCase>(() => UpdateToolInvocationRecordUseCase(getIt()));
}

// END GENERATED
