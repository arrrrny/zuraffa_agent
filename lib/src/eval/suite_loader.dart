// SuiteLoader for the eval harness (issue #115).
//
// Reads suite definitions from YAML files in the eval/suites/ directory.
// Each suite file defines a collection of golden mission tasks, the pass@k
// parameter k, and the gate threshold. The loader resolves the suite and
// its constituent task definitions.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../domain/entities/suite/suite.dart';

/// Exception thrown when a suite file cannot be loaded or parsed.
class SuiteLoadException implements Exception {
  final String message;

  const SuiteLoadException(this.message);

  @override
  String toString() => 'SuiteLoadException: $message';
}

/// Loads [Suite] definitions from YAML files.
///
/// Suite files are discovered in a directory (default: `eval/suites/`).
/// Each file must be valid YAML with the following structure:
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
  /// The directory containing suite YAML files.
  final String suiteDirectory;

  /// The file extension to look for (default: .yaml).
  final String fileExtension;

  const SuiteLoader({
    this.suiteDirectory = 'eval/suites',
    this.fileExtension = '.yaml',
  });

  /// Loads all suites from the configured directory.
  ///
  /// Returns a map of suite ID to [Suite] for all valid YAML files found.
  /// Files that cannot be parsed or validated are skipped and a warning
  /// is printed to stderr.
  Future<Map<String, Suite>> loadAll() async {
    final suites = <String, Suite>{};

    if (!await Directory(suiteDirectory).exists()) {
      return suites;
    }

    await for (final entity in Directory(suiteDirectory).list()) {
      if (entity is File && entity.path.endsWith(fileExtension)) {
        try {
          final suite = await loadFromFile(entity.path);
          suites[suite.id] = suite;
        } catch (e) {
          stderr.writeln('Warning: Could not load suite from ${entity.path}: $e');
        }
      }
    }

    return suites;
  }

  /// Loads a single suite from a YAML file path.
  Future<Suite> loadFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw SuiteLoadException('File not found: $filePath');
    }

    final content = await file.readAsString();
    return loadFromString(content, filePath);
  }

  /// Loads a suite from a YAML string.
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
