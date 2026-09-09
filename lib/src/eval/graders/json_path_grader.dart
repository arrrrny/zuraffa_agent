// HAND-CURATED — spec 111 (issue arrrrny/zuraffa_agent#125).
//
// JsonPathGrader — evaluates a documented JSONPath SUBSET against a JSON
// string payload: root `$`, dot property access (`.a.b`), and integer array
// indices (`[0]`). No external dependency; `dart:convert` decodes the
// payload. Missing paths, type mismatches, and malformed JSON FAIL with a
// reason — they never throw.

import 'dart:convert';

import 'grader.dart';

class JsonPathGrader implements Grader {
  final String path;

  /// The expected value at [path] (compared with `==`).
  final Object? expected;

  const JsonPathGrader({required this.path, required this.expected});

  @override
  String get id => 'json-path';

  @override
  Future<GraderResult> grade(String output) async {
    Object? payload;
    try {
      payload = jsonDecode(output);
    } on FormatException catch (e) {
      return GraderResult.fail(
        'json-path failed — payload is not valid JSON: ${e.message}',
      );
    }

    final tokens = _tokens(path);
    Object? current = payload;
    for (final token in tokens) {
      if (current is Map<String, dynamic>) {
        if (!current.containsKey(token)) {
          return GraderResult.fail(
            'json-path failed — "$token" not found at "$path"',
          );
        }
        current = current[token];
      } else if (current is List) {
        final index = int.tryParse(token);
        if (index == null || index < 0 || index >= current.length) {
          return GraderResult.fail(
            'json-path failed — index "[$token]" out of range at "$path"',
          );
        }
        current = current[index];
      } else {
        return GraderResult.fail(
          'json-path failed — cannot descend into "${current.runtimeType}" '
          'at "$path"',
        );
      }
    }

    if (current == expected) {
      return GraderResult.pass('resolved $path');
    }
    return GraderResult.fail(
      'json-path failed — $path resolved to "$current", expected "$expected"',
    );
  }

  /// `$.steps[2].status` → `['steps', '2', 'status']`.
  static List<String> _tokens(String path) {
    final body = path.startsWith(r'$.')
        ? path.substring(2)
        : path.replaceFirst(r'$', '');
    final normalized = body.replaceAllMapped(
      RegExp(r'\[\s*([0-9]+)\s*\]'),
      (m) => '.${m.group(1)}',
    );
    return normalized.split('.').where((t) => t.isNotEmpty).toList();
  }
}
