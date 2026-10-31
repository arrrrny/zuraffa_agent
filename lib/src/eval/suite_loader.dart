// SuiteLoader for the eval harness (issue #115).
//
// Parses suite definitions from YAML text. A suite file defines a collection
// of golden-mission task ids, the pass@k parameter k, and the gate threshold.
//
// The loader is pure (FR-005: the eval runtime is dart:io-free): it accepts
// file *contents*, never paths. Discovery and reading belong to the caller
// (the `tool/run_eval_suites.dart` CLI owns the dart:io boundary and feeds
// parsed-or-raw text in), which keeps this class outside the pipeline's
// dart:io purity allowlist.

import 'package:yaml/yaml.dart';

import '../domain/entities/suite/suite.dart';

/// Exception thrown when a suite definition cannot be parsed or validated.
class SuiteLoadException implements Exception {
  final String message;

  const SuiteLoadException(this.message);

  @override
  String toString() => 'SuiteLoadException: $message';
}

/// One suite file that failed to load, with the error that caused it.
///
/// Load failures are returned to the caller instead of swallowed: a corrupt
/// suite file must fail the release gate, not silently shrink it (the gate
/// would otherwise go green while a whole suite stops being gated).
class SuiteLoadError {
  /// The source label the caller keyed the content by (usually the path).
  final String source;

  final Object error;

  const SuiteLoadError(this.source, this.error);

  @override
  String toString() => '$source: $error';
}

/// The result of loading a catalog of suite files: every suite that parsed
/// and validated, plus every file that failed.
class SuiteCatalog {
  final Map<String, Suite> suites;

  final List<SuiteLoadError> failures;

  const SuiteCatalog(this.suites, this.failures);
}

/// Parses suite definitions from YAML text.
///
/// Suite YAML follows this structure:
///
/// ```yaml
/// id: suite-id
/// name: Human readable name
/// tasks:
///   - task_id_1
///   - task_id_2
/// k: 2
/// gate_threshold: 0.8
/// ```
class SuiteLoader {
  const SuiteLoader();

  /// Parses every entry of [yamlBySource] (source label → YAML text) and
  /// returns the catalog: suites that parsed, keyed by id, plus one
  /// [SuiteLoadError] per file that failed. Callers decide how failures gate
  /// the run — the release gate fails loudly on any of them.
  SuiteCatalog loadAll(Map<String, String> yamlBySource) {
    final suites = <String, Suite>{};
    final failures = <SuiteLoadError>[];
    for (final entry in yamlBySource.entries) {
      try {
        final suite = loadFromString(entry.value, entry.key);
        suites[suite.id] = suite;
      } catch (e) {
        failures.add(SuiteLoadError(entry.key, e));
      }
    }
    return SuiteCatalog(Map.unmodifiable(suites), List.unmodifiable(failures));
  }

  /// Parses a single suite from YAML text.
  ///
  /// [source] is used only for error reporting.
  Suite loadFromString(String yamlContent, [String source = 'string']) {
    final doc = loadYaml(yamlContent);

    if (doc is! YamlMap) {
      throw SuiteLoadException(
        'Expected YAML map at root in $source, got ${doc?.runtimeType}',
      );
    }

    final id = _getString(doc, 'id', source);
    final name = _getString(doc, 'name', source);
    final tasks = _getStringList(doc, 'tasks', source);
    final k = _getInt(doc, 'k', source);
    final gateThreshold = _getDouble(doc, 'gate_threshold', source);

    return Suite(
      id: id,
      name: name,
      tasks: tasks,
      k: k,
      gateThreshold: gateThreshold,
    );
  }

  String _getString(YamlMap doc, String key, String source) {
    final value = doc[key];
    if (value == null) {
      throw SuiteLoadException('Missing required field "$key" in $source');
    }
    if (value is! String) {
      throw SuiteLoadException(
        'Field "$key" must be a string in $source, got ${value.runtimeType}',
      );
    }
    return value;
  }

  List<String> _getStringList(YamlMap doc, String key, String source) {
    final value = doc[key];
    if (value == null) {
      throw SuiteLoadException('Missing required field "$key" in $source');
    }
    if (value is! YamlList) {
      throw SuiteLoadException(
        'Field "$key" must be a list in $source, got ${value.runtimeType}',
      );
    }
    return value.cast<String>().toList();
  }

  int _getInt(YamlMap doc, String key, String source) {
    final value = doc[key];
    if (value == null) {
      throw SuiteLoadException('Missing required field "$key" in $source');
    }
    if (value is! int) {
      throw SuiteLoadException(
        'Field "$key" must be an integer in $source, got ${value.runtimeType}',
      );
    }
    return value;
  }

  double _getDouble(YamlMap doc, String key, String source) {
    final value = doc[key];
    if (value == null) {
      throw SuiteLoadException('Missing required field "$key" in $source');
    }
    if (value is! double && value is! int) {
      throw SuiteLoadException(
        'Field "$key" must be a number in $source, got ${value.runtimeType}',
      );
    }
    return (value as num).toDouble();
  }
}
