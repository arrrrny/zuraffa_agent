// GENERATED - DO NOT EDIT
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_invocation_record/tool_invocation_record.dart';
import 'package:zuraffa_agent/src/domain/repositories/tool_invocation_record_repository.dart';
import 'package:zuraffa_agent/src/domain/usecases/tool_invocation_record/get_tool_invocation_record_usecase.dart';

class MockToolInvocationRecordRepository extends Mock
    implements ToolInvocationRecordRepository {}

class MockToolInvocationRecord extends Mock implements ToolInvocationRecord {}

void main() {
  late GetToolInvocationRecordUseCase useCase;
  late MockToolInvocationRecordRepository mockRepository;
  setUp(() {
    registerFallbackValue(const QueryParams<ToolInvocationRecord>());
    mockRepository = MockToolInvocationRecordRepository();
    useCase = GetToolInvocationRecordUseCase(mockRepository);
  });
  group('GetToolInvocationRecordUseCase', () {
    final tToolInvocationRecord = MockToolInvocationRecord();
    test('should call repository.get and return result', () async {
      when(() => mockRepository.get(any()))
          .thenAnswer((_) async => tToolInvocationRecord);
      final result = await useCase.call(
        QueryParams<ToolInvocationRecord>(
          filter: Eq(ToolInvocationRecordFields.id, '1'),
        ),
      );
      verify(() => mockRepository.get(any())).called(1);
      expect(result.isSuccess, true);
      expect(
        result.getOrElse(() => throw (Exception())),
        equals(tToolInvocationRecord),
      );
    });
    test('should return Failure when repository throws', () async {
      final exception = Exception('Error');
      when(() => mockRepository.get(any())).thenThrow(exception);
      final result = await useCase.call(
        QueryParams<ToolInvocationRecord>(
          filter: Eq(ToolInvocationRecordFields.id, '1'),
        ),
      );
      verify(() => mockRepository.get(any())).called(1);
      expect(result.isFailure, true);
    });
  });
}

// END GENERATED
