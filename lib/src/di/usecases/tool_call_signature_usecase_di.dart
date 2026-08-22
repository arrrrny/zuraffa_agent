// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/tool_call_signature/get_tool_call_signature_usecase.dart';
import '../../domain/usecases/tool_call_signature/update_tool_call_signature_usecase.dart';

void registerToolCallSignatureUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetToolCallSignatureUseCase>(() => GetToolCallSignatureUseCase(getIt()));
  getIt.registerLazySingleton<UpdateToolCallSignatureUseCase>(() => UpdateToolCallSignatureUseCase(getIt()));
}

// END GENERATED
