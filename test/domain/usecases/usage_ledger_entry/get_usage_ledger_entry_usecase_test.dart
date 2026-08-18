// GENERATED - DO NOT EDIT
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart';
import 'package:zuraffa_agent/src/domain/entities/usage_ledger_entry/usage_ledger_entry.dart';
import 'package:zuraffa_agent/src/domain/repositories/usage_ledger_entry_repository.dart';
import 'package:zuraffa_agent/src/domain/usecases/usage_ledger_entry/get_usage_ledger_entry_usecase.dart';

class MockUsageLedgerEntryRepository extends Mock
    implements UsageLedgerEntryRepository {}

class MockUsageLedgerEntry extends Mock implements UsageLedgerEntry {}

void main() {
  late GetUsageLedgerEntryUseCase useCase;
  late MockUsageLedgerEntryRepository mockRepository;
  setUp(() {
    registerFallbackValue(const QueryParams<UsageLedgerEntry>());
    mockRepository = MockUsageLedgerEntryRepository();
    useCase = GetUsageLedgerEntryUseCase(mockRepository);
  });
  group('GetUsageLedgerEntryUseCase', () {
    final tUsageLedgerEntry = MockUsageLedgerEntry();
    test('should call repository.get and return result', () async {
      when(() => mockRepository.get(any()))
          .thenAnswer((_) async => tUsageLedgerEntry);
      final result = await useCase.call(
        QueryParams<UsageLedgerEntry>(
          filter: Eq(UsageLedgerEntryFields.id, '1'),
        ),
      );
      verify(() => mockRepository.get(any())).called(1);
      expect(result.isSuccess, true);
      expect(
        result.getOrElse(() => throw (Exception())),
        equals(tUsageLedgerEntry),
      );
    });
    test('should return Failure when repository throws', () async {
      final exception = Exception('Error');
      when(() => mockRepository.get(any())).thenThrow(exception);
      final result = await useCase.call(
        QueryParams<UsageLedgerEntry>(
          filter: Eq(UsageLedgerEntryFields.id, '1'),
        ),
      );
      verify(() => mockRepository.get(any())).called(1);
      expect(result.isFailure, true);
    });
  });
}

// END GENERATED
