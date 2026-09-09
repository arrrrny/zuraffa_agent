// HAND-CURATED — spec 111 (issue arrrrny/zuraffa_agent#125).
//
// GraderRegistry — the bind-by-id resolution point golden missions use:
// register graders under stable ids, resolve bindings, evaluate in bulk.

import 'grader.dart';

class GraderRegistry {
  final Map<String, Grader> _graders = {};

  void register(Grader grader, {String? id}) {
    _graders[id ?? grader.id] = grader;
  }

  /// Resolves a grader by binding id. An unknown id throws a `StateError`
  /// naming it — binding typos must fail loudly, not silently skip grading.
  Grader resolve(String id) {
    final grader = _graders[id];
    if (grader == null) {
      throw StateError('GraderRegistry: no grader registered as "$id"');
    }
    return grader;
  }

  /// Evaluates one output per binding id, returning one verdict per id.
  Future<Map<String, GraderResult>> evaluateAll(
    Map<String, String> outputs,
  ) async {
    final verdicts = <String, GraderResult>{};
    for (final entry in outputs.entries) {
      verdicts[entry.key] = await resolve(entry.key).grade(entry.value);
    }
    return Map.unmodifiable(verdicts);
  }
}
