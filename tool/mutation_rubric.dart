// Formalized manual mutant rubric — issue #128 AC-1, option B ("formalize
// the manual mutant rubric as a CI script").
//
// specs/ROLLUP_VERIFICATION.md ran "deliberate mutants on highest-risk
// behaviors per spec: one small change, expect failure, restore exactly" —
// by hand. This script mechanizes exactly that loop:
//
//   for each registered mutant:
//     1. assert the `find` pattern occurs EXACTLY once in the target file
//        (a stale registry fails loudly instead of mutating the wrong line)
//     2. apply the mutation
//     3. run the SCOPED test command (issue #128: the fast, relevant slice —
//        never the whole suite per mutant; always `-j 2`, the fleet cap)
//     4. KILLED = tests failed (exit != 0); SURVIVED = tests passed
//     5. restore the file EXACTLY (try/finally — a crashed run never leaves
//        a mutant behind)
//
// Kill-rate gate: >= 80% (issue #128 AC-1). Exit 1 below the gate, on a
// stale registry entry, or on an unapplyable mutant.
//
// Usage:
//   dart run tool/mutation_rubric.dart [--filter <id>] [--report <path>]
//                                      [--gate <0..1>] [--keep-going]
//
// The registry anchors the historically-surviving mutant classes from
// ROLLUP_VERIFICATION.md ("Highest-risk findings"): boundary off-by-ones,
// dropped equality fields, vacuous guards, and inverted comparisons.
library;

import 'dart:convert';
import 'dart:io';

class _Mutant {
  final String id;
  final String file;
  final String find;
  final String replace;
  final String description;

  /// Test paths for the SCOPED run (relative to repo root).
  final List<String> testPaths;

  const _Mutant({
    required this.id,
    required this.file,
    required this.find,
    required this.replace,
    required this.description,
    required this.testPaths,
  });
}

/// The registry — one row per deliberate mutant. Each entry MUST keep
/// `find` unique within its file (the script enforces it).
const _registry = [
  // --- PassAtK (unbiased estimator) — boundary + closed-form mutants ------
  _Mutant(
    id: 'PAK-1',
    file: 'lib/src/domain/entities/pass_at_k/pass_at_k.dart',
    find: 'if (c == 0) return 0.0;',
    replace: 'if (c == 0) return 1.0;',
    description: 'zero-correct boundary flips to perfect score',
    testPaths: [
      'test/property/pass_at_k_property_test.dart',
      'test/domain/entities/pass_at_k',
    ],
  ),
  _Mutant(
    id: 'PAK-2',
    file: 'lib/src/domain/entities/pass_at_k/pass_at_k.dart',
    find: 'if (n - c < k) return 1.0;',
    replace: 'if (n - c <= k) return 1.0;',
    description: 'perfect-score boundary shifts one off (c == n - k case)',
    testPaths: [
      'test/property/pass_at_k_property_test.dart',
      'test/domain/entities/pass_at_k',
    ],
  ),
  _Mutant(
    id: 'PAK-3',
    file: 'lib/src/domain/entities/pass_at_k/pass_at_k.dart',
    find: 'if (b < 0 || b > a) return 0;',
    replace: 'if (b < 0 || b > a) return 1;',
    description: 'out-of-range binomial returns 1 instead of 0',
    testPaths: [
      'test/property/pass_at_k_property_test.dart',
      'test/domain/entities/pass_at_k',
    ],
  ),
  // --- UiTreePayload — structural walkers + wire validation ---------------
  _Mutant(
    id: 'UIT-1',
    file: 'lib/src/domain/entities/ui_tree_payload/ui_tree_payload.dart',
    find: 'if (parsedMime is! String || parsedMime != mimeType) {',
    replace: 'if (parsedMime is! Never || parsedMime != mimeType) {',
    description: 'mimeType contract check degenerates (never trips)',
    testPaths: [
      'test/property/ui_tree_payload_property_test.dart',
      'test/domain/entities/ui_tree_payload',
    ],
  ),
  _Mutant(
    id: 'UIT-2',
    file: 'lib/src/domain/entities/ui_tree_payload/ui_tree_payload.dart',
    find: 'if (d > maxChildDepth) maxChildDepth = d;',
    replace: 'if (d < maxChildDepth) maxChildDepth = d;',
    description: 'depth walker keeps the SHALLOWEST branch',
    testPaths: [
      'test/property/ui_tree_payload_property_test.dart',
      'test/domain/entities/ui_tree_payload',
    ],
  ),
  // --- CircuitBreaker (spec 035 value object) — transition boundaries -----
  _Mutant(
    id: 'CBD-1',
    file: 'lib/src/domain/entities/circuit_breaker/circuit_breaker.dart',
    find: 'if (newCount >= failureThreshold) {',
    replace: 'if (newCount > failureThreshold) {',
    description: 'trip threshold off-by-one (never trips at threshold)',
    testPaths: [
      'test/property/circuit_breaker_property_test.dart',
      'test/domain/entities/circuit_breaker',
    ],
  ),
  _Mutant(
    id: 'CBD-2',
    file: 'lib/src/domain/entities/circuit_breaker/circuit_breaker.dart',
    find: 'if (elapsed < cooldown) {',
    replace: 'if (elapsed <= cooldown) {',
    description: 'inclusive cooldown boundary becomes exclusive',
    testPaths: [
      'test/property/circuit_breaker_property_test.dart',
      'test/domain/entities/circuit_breaker',
    ],
  ),
  // --- CircuitBreaker (spec 008 runtime) — trip + cooldown boundaries -----
  _Mutant(
    id: 'CBR-1',
    file: 'lib/src/llm/circuit_breaker.dart',
    find: 'if (_consecutiveFailures >= maxConsecutiveFailures) {',
    replace: 'if (_consecutiveFailures > maxConsecutiveFailures) {',
    description: 'runtime trip threshold off-by-one',
    testPaths: [
      'test/property/circuit_breaker_property_test.dart',
      'test/llm/circuit_breaker_test.dart',
    ],
  ),
  _Mutant(
    id: 'CBR-2',
    file: 'lib/src/llm/circuit_breaker.dart',
    find: 'difference(lastFailure).inMilliseconds >=',
    replace: 'difference(lastFailure).inMilliseconds >',
    description: 'runtime cooldown boundary becomes exclusive',
    testPaths: [
      'test/property/circuit_breaker_property_test.dart',
      'test/llm/circuit_breaker_test.dart',
    ],
  ),
  // --- Historically surviving mutants (ROLLUP_VERIFICATION.md) ------------
  _Mutant(
    id: 'STP-1',
    file: 'lib/src/domain/entities/stop_policy/stop_policy.dart',
    find: 'enabled == other.enabled);',
    replace: 'true == other.enabled);',
    description:
        'operator == drops the enabled field (rollup finding U2 class)',
    testPaths: ['test/domain/entities/stop_policy'],
  ),
  _Mutant(
    id: 'ENG-1',
    file: 'lib/src/data/providers/engine_loop/engine_loop_executor.dart',
    find: 'if (turnNumber > loop.maxTurns) {',
    replace: 'if (turnNumber >= loop.maxTurns) {',
    description:
        'runTurn upper bound off-by-one at the cap (rollup finding U7 class)',
    testPaths: ['test/data/providers/engine_loop'],
  ),
];

void main(List<String> args) {
  final filter = _argValue(args, '--filter');
  final reportPath = _argValue(args, '--report');
  final gateArg = _argValue(args, '--gate');
  final keepGoing = args.contains('--keep-going');
  final gate = gateArg == null ? 0.80 : double.tryParse(gateArg);
  if (gate == null || gate < 0 || gate > 1) {
    stderr.writeln('--gate must be a number in [0, 1], got: "$gateArg"');
    exit(2);
  }

  final mutants = [
    for (final m in _registry)
      if (filter == null || m.id == filter) m,
  ];
  if (mutants.isEmpty) {
    stderr.writeln('no mutants matched filter "$filter"');
    exit(2);
  }

  final results = <Map<String, dynamic>>[];
  var killed = 0;
  var errors = 0;

  mutantLoop:
  for (final mutant in mutants) {
    stdout.write('${mutant.id}  ${mutant.description}\n  ... ');
    final outcome = _runMutant(mutant);
    results.add({
      'id': mutant.id,
      'file': mutant.file,
      'description': mutant.description,
      ...outcome,
    });
    switch (outcome['status']) {
      case 'killed':
        killed++;
        stdout.writeln('KILLED');
      case 'survived':
        stdout.writeln('SURVIVED  <-- tests did not catch this mutant');
      default:
        errors++;
        stdout.writeln('ERROR: ${outcome['detail']}');
        if (!keepGoing) break mutantLoop;
    }
  }

  final total = killed + results.where((r) => r['status'] == 'survived').length;
  final rate = total == 0 ? 0.0 : killed / total;
  final passedGate = rate >= gate && errors == 0;

  final report = {
    'checkedAt': DateTime.now().toUtc().toIso8601String(),
    'gate': gate,
    'mutants': results,
    'killed': killed,
    'survived': total - killed,
    'errors': errors,
    'killRate': rate,
    'passedGate': passedGate,
  };
  final encoded = const JsonEncoder.withIndent('  ').convert(report);
  if (reportPath != null) {
    File(reportPath).writeAsStringSync('$encoded\n');
    stdout.writeln('report written to $reportPath');
  }

  stdout.writeln(
    '\nkill rate: $killed/$total = ${(rate * 100).toStringAsFixed(1)}% '
    '(gate: ${(gate * 100).toStringAsFixed(1)}%) — '
    '${passedGate ? 'PASS' : 'FAIL'}',
  );
  if (!passedGate) exit(1);
}

Map<String, dynamic> _runMutant(_Mutant mutant) {
  final file = File(mutant.file);
  if (!file.existsSync()) {
    return {'status': 'error', 'detail': 'target file missing: ${mutant.file}'};
  }
  final original = file.readAsStringSync();
  final occurrences = original.split(mutant.find).length - 1;
  if (occurrences != 1) {
    return {
      'status': 'error',
      'detail':
          'registry stale: "${mutant.find}" occurs $occurrences times in '
          '${mutant.file} (expected exactly 1) — update the rubric',
    };
  }

  try {
    file.writeAsStringSync(original.replaceFirst(mutant.find, mutant.replace));
    final result = Process.runSync(
      'dart',
      ['test', ...mutant.testPaths, '-j', '2', '--reporter', 'compact'],
      runInShell: true,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    // A killed mutant is one the tests DETECT: any non-zero exit (test
    // failure or compile error introduced by the mutation).
    final killed = result.exitCode != 0;
    return {
      'status': killed ? 'killed' : 'survived',
      'testExitCode': result.exitCode,
      if (!killed)
        'detail':
            'scoped suite green under mutation (${mutant.testPaths.join(" ")})',
    };
  } on ProcessException catch (error) {
    return {'status': 'error', 'detail': 'process failed: $error'};
  } finally {
    // Restore EXACTLY — even when the test run throws or the script is
    // interrupted mid-flight (the rollup's incident discipline).
    file.writeAsStringSync(original);
  }
}

String? _argValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index < 0 || index + 1 >= args.length) return null;
  return args[index + 1];
}
