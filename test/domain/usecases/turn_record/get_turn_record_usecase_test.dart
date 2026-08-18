// GENERATED - DO NOT EDIT
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart';
import 'package:zuraffa_agent/src/domain/entities/turn_record/turn_record.dart';
import 'package:zuraffa_agent/src/domain/repositories/turn_record_repository.dart';
import 'package:zuraffa_agent/src/domain/usecases/turn_record/get_turn_record_usecase.dart';

class MockTurnRecordRepository extends Mock implements TurnRecordRepository {}

class MockTurnRecord extends Mock implements TurnRecord {}

void main() {
  late GetTurnRecordUseCase useCase;
  late MockTurnRecordRepository mockRepository;
  setUp(() {
    registerFallbackValue(const QueryParams<TurnRecord>());
    mockRepository = MockTurnRecordRepository();
    useCase = GetTurnRecordUseCase(mockRepository);
  });
  group('GetTurnRecordUseCase', () {
    final tTurnRecord = MockTurnRecord();
    test('should call repository.get and return result', () async {
      when(() => mockRepository.get(any()))
          .thenAnswer((_) async => tTurnRecord);
      final result = await useCase.call(
        QueryParams<TurnRecord>(filter: Eq(TurnRecordFields.id, '1')),
      );
      verify(() => mockRepository.get(any())).called(1);
      expect(result.isSuccess, true);
      expect(result.getOrElse(() => throw (Exception())), equals(tTurnRecord));
    });
    test('should return Failure when repository throws', () async {
      final exception = Exception('Error');
      when(() => mockRepository.get(any())).thenThrow(exception);
      final result = await useCase.call(
        QueryParams<TurnRecord>(filter: Eq(TurnRecordFields.id, '1')),
      );
      verify(() => mockRepository.get(any())).called(1);
      expect(result.isFailure, true);
    });
  });
}

// END GENERATED
