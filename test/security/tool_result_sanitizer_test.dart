// spec 109 (issue #118) — ToolResultSanitizer: default regex rules,
// benign pass-through, and configurability.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/security/tool_result_sanitizer.dart';

// Synthetic fixtures, assembled at runtime: each string matches the
// rule's regex but is fabricated here (not a real credential), and the
// concatenation keeps placeholder token shapes out of the source text so
// GitHub push protection doesn't mistake them for leaked secrets.
const awsKey =
    'AKIA'
    'IOSFODNN7EXAMPLE';
final ghPat = 'ghp_' + 'a' * 36;
final jwt =
    'eyJhbGciOiJIUzI1NiJ9'
    '.eyJzdWIiOiIxMjM0NTY3ODkwIn0'
    '.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
final slack = 'xoxb-${'1' * 12}-${'aB' * 6}';
final stripe = 'sk_live_' + 'a' * 24;

void expectRedacted(SanitizedToolResult r, String rule, String secret) {
  expect(r.content, contains('[REDACTED:$rule]'));
  expect(r.content, isNot(contains(secret)));
  expect(r.matchedRules, contains(rule));
}

void main() {
  group('spec 109 — default rules (issue #118)', () {
    test('U1: AWS access key id redacted', () {
      const secret = awsKey;
      final r = RegexToolResultSanitizer().sanitize(
        'config loaded: $secret from env',
      );
      expectRedacted(r, 'aws-access-key-id', secret);
      expect(r.content, 'config loaded: [REDACTED:aws-access-key-id] from env');
    });

    test('U2: GitHub PAT redacted', () {
      final secret = ghPat;
      final r = RegexToolResultSanitizer().sanitize(
        'token: $secret — scope repo',
      );
      expectRedacted(r, 'github-pat', secret);
    });

    test('U3: JWT redacted', () {
      final secret = jwt;
      final r = RegexToolResultSanitizer().sanitize(
        'authorization: Bearer $secret',
      );
      expectRedacted(r, 'jwt', secret);
    });

    test('U4: private-key block header redacted', () {
      const secret = '-----BEGIN RSA PRIVATE KEY-----';
      final r = RegexToolResultSanitizer().sanitize(
        'key material follows:\n$secret\nAAAA...',
      );
      expectRedacted(r, 'private-key-header', secret);
    });

    test('U5: Slack token redacted', () {
      final secret = slack;
      final r = RegexToolResultSanitizer().sanitize('slack: $secret');
      expectRedacted(r, 'slack-token', secret);
    });

    test('U6: Stripe live key redacted', () {
      final secret = stripe;
      final r = RegexToolResultSanitizer().sanitize('payment key: $secret');
      expectRedacted(r, 'stripe-live-key', secret);
    });

    test('U7: benign corpus round-trips unchanged, zero matched rules', () {
      const benign =
          'AKIA is the AWS prefix\n'
          'run ghp_build job\n'
          'xoxo gossip\n'
          '-----BEGIN CERTIFICATE-----\n'
          'sk_live is mentioned in docs\n'
          'eyJ is not a token here\n'
          'normal log line with path /var/log/app and 200 OK\n';
      final r = RegexToolResultSanitizer().sanitize(benign);
      expect(r.content, benign);
      expect(r.matchedRules, isEmpty);
    });

    test('U8: config — disabled rule, custom pattern, custom marker', () {
      const secret = awsKey;
      // Disabled rule: secret passes through untouched.
      final disabled = RegexToolResultSanitizer(
        config: SanitizerConfig(disabledRules: {'aws-access-key-id'}),
      ).sanitize('key: $secret');
      expect(disabled.content, contains(secret));
      expect(disabled.matchedRules, isEmpty);

      // Custom pattern fires under its own name.
      final custom = RegexToolResultSanitizer(
        config: SanitizerConfig(
          customPatterns: {'internal-key': RegExp(r'INTKEY-[0-9]{8}')},
        ),
      ).sanitize('found INTKEY-12345678 in output');
      expect(custom.content, contains('[REDACTED:internal-key]'));
      expect(custom.matchedRules, contains('internal-key'));

      // Custom marker template honored.
      final markered = RegexToolResultSanitizer(
        config: SanitizerConfig(markerTemplate: '<REMOVED:{rule}>'),
      ).sanitize('key: $awsKey');
      expect(markered.content, contains('<REMOVED:aws-access-key-id>'));
    });
  });
}
