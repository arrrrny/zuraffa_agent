/// Default secret patterns + opt-in labeling (FR-005, SC-006,
/// contracts/observability.md).
///
/// Pure Dart; no pi dependency. [SecretScrubber.defaults] reuses the regex set
/// from spec 109's `ToolResultSanitizer` (awsKey, githubPat, jwt,
/// privateKeyHeader, slackToken, stripeLiveKey) plus email/phone for general
/// PII. A pattern that fails to compile or a scrub that throws surfaces as a
/// [SecretScrubberError] so the caller can fail closed (FR-003, SC-002).
library;

import '../governance/entities/redaction_rule.dart';

/// Thrown when a [RedactionRule] pattern is invalid or a scrub fails. The
/// caller turns this into a typed fail-closed outcome (FR-003).
class SecretScrubberError implements Exception {
  final String message;
  final Object? cause;

  const SecretScrubberError(this.message, {this.cause});

  @override
  String toString() => 'SecretScrubberError: $message';
}

/// Scrubs secret-like substrings out of a payload before it is persisted or
/// sent to a model/provider (FR-005).
class SecretScrubber {
  final List<RedactionRule> rules;

  /// Compiled patterns, paired with their rule. Built once at construction so
  /// a bad pattern fails at construction rather than mid-scrub.
  final List<(RedactionRule, RegExp)> _compiled;

  SecretScrubber({required this.rules}) : _compiled = _compile(rules);

  /// The default rule set: spec 109's six secret patterns plus email/phone.
  factory SecretScrubber.defaults() => SecretScrubber(
    rules: [
      RedactionRule(
        name: 'aws-access-key-id',
        pattern: r'AKIA[0-9A-Z]{16}',
        replacement: '[REDACTED:aws-access-key-id]',
      ),
      RedactionRule(
        name: 'github-pat',
        pattern: r'gh[pousr]_[A-Za-z0-9]{36,}',
        replacement: '[REDACTED:github-pat]',
      ),
      RedactionRule(
        name: 'jwt',
        pattern: r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+',
        replacement: '[REDACTED:jwt]',
      ),
      RedactionRule(
        name: 'private-key-header',
        pattern: r'-----BEGIN [A-Z ]*PRIVATE KEY-----',
        replacement: '[REDACTED:private-key-header]',
      ),
      RedactionRule(
        name: 'slack-token',
        pattern: r'xox[abprs]-[A-Za-z0-9-]{10,}',
        replacement: '[REDACTED:slack-token]',
      ),
      RedactionRule(
        name: 'stripe-live-key',
        pattern: r'[sr]k_live_[A-Za-z0-9]{20,}',
        replacement: '[REDACTED:stripe-live-key]',
      ),
      RedactionRule(
        name: 'email',
        pattern: r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}',
        replacement: '[REDACTED:email]',
      ),
      // Deliberately broad: a conservative default that also matches benign
      // long digit runs (order IDs, epoch timestamps). Hosts that need tighter
      // PII matching should construct SecretScrubber with their own rules.
      RedactionRule(
        name: 'phone',
        pattern: r'\+?\d[\d\s().-]{7,}\d',
        replacement: '[REDACTED:phone]',
      ),
    ],
  );

  static List<(RedactionRule, RegExp)> _compile(List<RedactionRule> rules) {
    final compiled = <(RedactionRule, RegExp)>[];
    for (final rule in rules) {
      try {
        compiled.add((rule, RegExp(rule.pattern)));
      } on FormatException catch (e) {
        throw SecretScrubberError(
          'invalid pattern for rule "${rule.name}"',
          cause: e,
        );
      }
    }
    return compiled;
  }

  /// Whether [payload] contains any secret-like substring.
  bool matches(String payload) {
    for (final (_, pattern) in _compiled) {
      if (pattern.hasMatch(payload)) return true;
    }
    return false;
  }

  /// Returns [payload] with every secret-like substring replaced by its rule's
  /// replacement token. Throws [SecretScrubberError] on failure so the caller
  /// fails closed (FR-003).
  String scrub(String payload) {
    try {
      var out = payload;
      for (final (rule, pattern) in _compiled) {
        out = out.replaceAllMapped(pattern, (_) => rule.replacement);
      }
      return out;
    } catch (e) {
      throw SecretScrubberError('scrub failed', cause: e);
    }
  }
}
