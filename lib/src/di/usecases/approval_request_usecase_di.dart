// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/approval_request/get_approval_request_usecase.dart';
import '../../domain/usecases/approval_request/update_approval_request_usecase.dart';

void registerApprovalRequestUseCase(GetIt getIt) {
  getIt.registerLazySingleton<GetApprovalRequestUseCase>(() => GetApprovalRequestUseCase(getIt()));
  getIt.registerLazySingleton<UpdateApprovalRequestUseCase>(() => UpdateApprovalRequestUseCase(getIt()));
}

// END GENERATED
