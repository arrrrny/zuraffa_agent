// Regression test for arrrrny/zuraffa_agent#25 + #26.
//
// Verifies the RepetitionTrackerMockDatasource resolves cleanly:
// - import resolves (uri_does_not_exist is gone)
// - implements clause resolves (implements_non_class is gone)
// - mock bodies throw UnimplementedError as designed

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/data/datasources/repetition_tracker/repetition_tracker_datasource.dart';
import 'package:zuraffa_agent/src/data/datasources/repetition_tracker/repetition_tracker_mock_datasource.dart';

void main() {
  group('arrarrny/zuraffa_agent#25 + #26 — RepetitionTracker datasource pair', () {
    test('RepetitionTrackerMockDatasource is a RepetitionTrackerDatasource', () {
      expect(RepetitionTrackerMockDatasource(), isA<RepetitionTrackerDatasource>());
    });

    test('RepetitionTrackerMockDatasource.current throws UnimplementedError', () {
      expect(
        () => RepetitionTrackerMockDatasource().current(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('RepetitionTrackerMockDatasource.reset throws UnimplementedError', () {
      expect(
        () => RepetitionTrackerMockDatasource().reset(),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
