// GENERATED - DO NOT EDIT
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart';
import 'package:zuraffa_agent/src/domain/entities/usage_ledger_entry/usage_ledger_entry.dart';
import 'package:zuraffa_agent/src/domain/repositories/usage_ledger_entry_repository.dart';
import 'package:zuraffa_agent/src/domain/usecases/usage_ledger_entry/update_usage_ledger_entry_usecase.dart';

class MockUsageLedgerEntryRepository extends Mock
    implements UsageLedgerEntryRepository {}

class MockUsageLedgerEntry extends Mock implements UsageLedgerEntry {}

void main() {
  late UpdateUsageLedgerEntryUseCase useCase;
  late MockUsageLedgerEntryRepository mockRepository;
  setUp(() {
    registerFallbackValue(
      UpdateParams<String, UsageLedgerEntryPatch>(
        id: '1',
        data: UsageLedgerEntryPatch(),
      ),
    );
    mockRepository = MockUsageLedgerEntryRepository();
    useCase = UpdateUsageLedgerEntryUseCase(mockRepository);
  });
  group('UpdateUsageLedgerEntryUseCase', () {
    final tUsageLedgerEntry = MockUsageLedgerEntry();
    test('should call repository.update and return result', () async {
      when(() => mockRepository.update(any()))
          .thenAnswer((_) async => tUsageLedgerEntry);
      final result = await useCase.call(
        UpdateParams<String, UsageLedgerEntryPatch>(
          id: '1',
          data: UsageLedgerEntryPatch(),
        ),
      );
      verify(() => mockRepository.update(any())).called(1);
      expect(result.isSuccess, true);
      expect(
        result.getOrElse(() => throw (Exception())),
        equals(tUsageLedgerEntry),
      );
    });
    test('should return Failure when repository throws', () async {
      final exception = Exception('Error');
      when(() => mockRepository.update(any())).thenThrow(exception);
      final result = await useCase.call(
        UpdateParams<String, UsageLedgerEntryPatch>(
          id: '1',
          data: UsageLedgerEntryPatch(),
        ),
      );
      verify(() => mockRepository.update(any())).called(1);
      expect(result.isFailure, true);
    });
  });
}

// END GENERATED
