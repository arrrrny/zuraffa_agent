// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../domain/usecases/enums/update_enums_usecase.dart';
import '../../domain/usecases/enums/get_enums_usecase.dart';

void registerEnumsUseCase(GetIt getIt) {
  getIt.registerLazySingleton<UpdateEnumsUseCase>(() => UpdateEnumsUseCase(getIt()));
  getIt.registerLazySingleton<GetEnumsUseCase>(() => GetEnumsUseCase(getIt()));
}

// END GENERATED
