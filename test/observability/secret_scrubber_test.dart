// SecretScrubber tests (FR-005, SC-006, contracts/observability.md).
//
// The scrubber redacts secret-like payloads by default (awsKey, githubPat,
// jwt, privateKeyHeader, slackToken, stripeLiveKey) plus general PII
// (email, phone). A scrubber failure fails closed (FR-003) — the caller
// turns a thrown [SecretScrubberError] into a typed fail-closed outcome.
import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() {
  group('SecretScrubber.defaults', () {
    final scrubber = SecretScrubber.defaults();

    test('redacts an AWS access key id', () {
      // Built by concatenation so the literal key shape never sits in source
      // (GitHub push protection would otherwise flag the fixture).
      final key =
          'AK'
          'IA'
          'ABCDEFGHIJKLMNOP';
      final out = scrubber.scrub('key $key here');
      expect(out, contains('[REDACTED:aws-access-key-id]'));
      expect(out, isNot(contains(key)));
    });

    test('redacts a github PAT', () {
      final key =
          'gh'
          'p_'
          'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final out = scrubber.scrub('token $key');
      expect(out, contains('[REDACTED:github-pat]'));
      expect(out, isNot(contains(key)));
    });

    test('redacts a JWT', () {
      final out = scrubber.scrub(
        'auth eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.abcdefghijklmnop',
      );
      expect(out, contains('[REDACTED:jwt]'));
    });

    test('redacts a private key header', () {
      final out = scrubber.scrub('-----BEGIN RSA PRIVATE KEY-----');
      expect(out, contains('[REDACTED:private-key-header]'));
    });

    test('redacts a slack token', () {
      final key =
          'xox'
          'b-1234567890-abcdefghij';
      final out = scrubber.scrub('slack $key');
      expect(out, contains('[REDACTED:slack-token]'));
      expect(out, isNot(contains(key)));
    });

    test('redacts a stripe live key', () {
      final key =
          'sk'
          '_live_'
          'ABCDEFGHIJKLMNOPQRSTUVWX';
      final out = scrubber.scrub('stripe $key');
      expect(out, contains('[REDACTED:stripe-live-key]'));
      expect(out, isNot(contains(key)));
    });

    test('redacts an email address', () {
      final out = scrubber.scrub('contact me at jane.doe@example.com now');
      expect(out, contains('[REDACTED:email]'));
      expect(out, isNot(contains('jane.doe@example.com')));
    });

    test('leaves a benign payload unchanged', () {
      const benign = 'the quick brown fox jumps over the lazy dog 12345';
      expect(scrubber.scrub(benign), benign);
      expect(scrubber.matches(benign), isFalse);
    });

    test('matches reports true for a secret-bearing payload', () {
      final key =
          'AK'
          'IA'
          'ABCDEFGHIJKLMNOP';
      expect(scrubber.matches(key), isTrue);
    });
  });

  group('SecretScrubber custom + failure', () {
    test('a custom rule set is applied', () {
      final scrubber = SecretScrubber(
        rules: [
          RedactionRule(
            name: 'ticket',
            pattern: r'TICKET-\d+',
            replacement: '[REDACTED:ticket]',
          ),
        ],
      );
      expect(
        scrubber.scrub('see TICKET-42 for details'),
        'see [REDACTED:ticket] for details',
      );
    });

    test('an invalid pattern fails closed with SecretScrubberError', () {
      expect(
        () => SecretScrubber(
          rules: [
            RedactionRule(name: 'broken', pattern: r'(', replacement: 'x'),
          ],
        ),
        throwsA(isA<SecretScrubberError>()),
      );
    });
  });
}
