// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/turn_record/turn_record.dart';
import 'turn_record_datasource.dart';

class TurnRecordRemoteDataSource
    with Loggable, FailureHandler
    implements TurnRecordDataSource {
  @override
  Future<TurnRecord> get(QueryParams<TurnRecord> params) async {
    throw UnimplementedError('Implement remote get');
  }

  @override
  Future<List<TurnRecord>> getList(ListQueryParams<TurnRecord> params) async {
    throw UnimplementedError('Implement remote getList');
  }

  @override
  Future<TurnRecord> create(TurnRecord turnRecord) async {
    throw UnimplementedError('Implement remote create');
  }

  @override
  Future<TurnRecord> update(
    UpdateParams<String, TurnRecordPatch> params,
  ) async {
    throw UnimplementedError('Implement remote update');
  }

  @override
  Future<void> delete(DeleteParams<String> params) async {
    throw UnimplementedError('Implement remote delete');
  }
}

// END GENERATED
