// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/turn_record/turn_record.dart';

abstract class TurnRecordDataSource with Loggable, FailureHandler {
  Future<TurnRecord> get(QueryParams<TurnRecord> params);
  Future<List<TurnRecord>> getList(ListQueryParams<TurnRecord> params);
  Future<TurnRecord> create(TurnRecord turnRecord);
  Future<TurnRecord> update(UpdateParams<String, TurnRecordPatch> params);
  Future<void> delete(DeleteParams<String> params);
}

// END GENERATED
