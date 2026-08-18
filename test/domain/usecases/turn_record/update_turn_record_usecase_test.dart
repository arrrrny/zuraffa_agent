// GENERATED - DO NOT EDIT
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart';
import 'package:zuraffa_agent/src/domain/entities/turn_record/turn_record.dart';
import 'package:zuraffa_agent/src/domain/repositories/turn_record_repository.dart';
import 'package:zuraffa_agent/src/domain/usecases/turn_record/update_turn_record_usecase.dart';

class MockTurnRecordRepository extends Mock implements TurnRecordRepository {}

class MockTurnRecord extends Mock implements TurnRecord {}

void main() {
  late UpdateTurnRecordUseCase useCase;
  late MockTurnRecordRepository mockRepository;
  setUp(() {
    registerFallbackValue(
      UpdateParams<String, TurnRecordPatch>(id: '1', data: TurnRecordPatch()),
    );
    mockRepository = MockTurnRecordRepository();
    useCase = UpdateTurnRecordUseCase(mockRepository);
  });
  group('UpdateTurnRecordUseCase', () {
    final tTurnRecord = MockTurnRecord();
    test('should call repository.update and return result', () async {
      when(() => mockRepository.update(any()))
          .thenAnswer((_) async => tTurnRecord);
      final result = await useCase.call(
        UpdateParams<String, TurnRecordPatch>(id: '1', data: TurnRecordPatch()),
      );
      verify(() => mockRepository.update(any())).called(1);
      expect(result.isSuccess, true);
      expect(result.getOrElse(() => throw (Exception())), equals(tTurnRecord));
    });
    test('should return Failure when repository throws', () async {
      final exception = Exception('Error');
      when(() => mockRepository.update(any())).thenThrow(exception);
      final result = await useCase.call(
        UpdateParams<String, TurnRecordPatch>(id: '1', data: TurnRecordPatch()),
      );
      verify(() => mockRepository.update(any())).called(1);
      expect(result.isFailure, true);
    });
  });
}

// END GENERATED
