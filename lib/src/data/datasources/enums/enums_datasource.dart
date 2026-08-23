// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/enums/enums.dart';

abstract class EnumsDataSource with Loggable, FailureHandler {
  Future<Enums> get(QueryParams<Enums> params);
  Future<Enums> update(UpdateParams<String, EnumsPatch> params);
}

// END GENERATED
