// HAND-CURATED — spec 109 (issue arrrrny/zuraffa_agent#118).
//
// ToolResultSanitizer — scrubs credential material out of tool output at
// the LLM egress boundary: the mission transcript is what the next request
// relays to the model vendor, so secrets leaving a tool must be replaced
// with named markers before that join. Pure and deterministic: no I/O, no
// clock, same input → same output.

/// List equality/hash helpers (no collection package dependency).
class _ListEquality {
  const _ListEquality();

  bool equals(List<String>? a, List<String>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  int hash(List<String>? list) => Object.hashAll(list ?? const <String>[]);
}

const _listEquality = _ListEquality();

/// The result of sanitizing one tool-output string.
class SanitizedToolResult {
  /// Content safe to join to the transcript / relay to the LLM.
  final String content;

  /// Names of the rules that matched and redacted something, in match
  /// order. Forward-compatible hook for a future audit log (issue #118's
  /// deferred acceptance).
  final List<String> matchedRules;

  const SanitizedToolResult({
    required this.content,
    required this.matchedRules,
  });

  @override
  bool operator ==(Object other) =>
      other is SanitizedToolResult &&
      other.content == content &&
      _listEquality.equals(other.matchedRules, matchedRules);

  @override
  int get hashCode => Object.hash(content, _listEquality.hash(matchedRules));

  @override
  String toString() =>
      'SanitizedToolResult(${content.length} chars, redacted by: $matchedRules)';
}

/// Redacts credential material from tool output before it reaches the LLM.
abstract class ToolResultSanitizer {
  const ToolResultSanitizer();

  SanitizedToolResult sanitize(String content);
}

/// Sanitizer configuration (issue #118's "configurable" acceptance):
/// - [disabledRules]: built-in rule names to skip.
/// - [customPatterns]: additional name → pattern rules.
/// - [markerTemplate]: replacement template; `{rule}` is substituted with
///   the matching rule's name.
class SanitizerConfig {
  final Set<String> disabledRules;
  final Map<String, RegExp> customPatterns;
  final String markerTemplate;

  static const String defaultMarkerTemplate = '[REDACTED:{rule}]';

  const SanitizerConfig({
    this.disabledRules = const {},
    this.customPatterns = const {},
    this.markerTemplate = defaultMarkerTemplate,
  });
}

/// A single redaction rule: a name and the pattern that identifies the
/// secret material.
class _Rule {
  final String name;
  final RegExp pattern;
  const _Rule(this.name, this.pattern);
}

/// The default implementation: regex rules over the credential shapes that
/// most commonly leak through file-reading and shell tools.
class RegexToolResultSanitizer implements ToolResultSanitizer {
  static const Map<String, String> _defaultPatterns = {
    // AWS access key id (the secret-access-key shape is too generic to
    // match without false positives; the key id alone is credential
    // material).
    'aws-access-key-id': r'AKIA[0-9A-Z]{16}',
    // GitHub tokens: ghp_ (classic PAT), gho_ (OAuth), ghu_ (user), ghs_
    // (server), ghr_ (refresh) + 36+ token chars.
    'github-pat': r'gh[pousr]_[A-Za-z0-9]{36,}',
    // JWT: three base64url segments, header segment always starts eyJ.
    'jwt': r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+',
    // PEM private-key block headers (any algorithm).
    'private-key-header': r'-----BEGIN [A-Z ]*PRIVATE KEY-----',
    // Slack bot/user/app/refresh tokens.
    'slack-token': r'xox[abprs]-[A-Za-z0-9-]{10,}',
    // Stripe live keys (test keys are not secrets).
    'stripe-live-key': r'[sr]k_live_[A-Za-z0-9]{20,}',
  };

  final SanitizerConfig config;
  final List<_Rule> _rules;

  RegexToolResultSanitizer({this.config = const SanitizerConfig()})
    : _rules = _buildRules(config);

  static List<_Rule> _buildRules(SanitizerConfig config) {
    final rules = <_Rule>[];
    _defaultPatterns.forEach((name, pattern) {
      if (!config.disabledRules.contains(name)) {
        rules.add(_Rule(name, RegExp(pattern)));
      }
    });
    config.customPatterns.forEach((name, pattern) {
      rules.add(_Rule(name, pattern));
    });
    return List.unmodifiable(rules);
  }

  @override
  SanitizedToolResult sanitize(String content) {
    var sanitized = content;
    final matched = <String>[];
    for (final rule in _rules) {
      if (!rule.pattern.hasMatch(sanitized)) continue;
      final marker = config.markerTemplate.replaceAll('{rule}', rule.name);
      sanitized = sanitized.replaceAllMapped(rule.pattern, (_) => marker);
      matched.add(rule.name);
    }
    return SanitizedToolResult(content: sanitized, matchedRules: matched);
  }
}
