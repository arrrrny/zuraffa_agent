// Mini property-based testing harness — issue #128.
//
// Zero new pub dependencies: the issue's minimum bar is "randomized loop
// tests", so this harness drives N trials of a property body with a SEEDED
// dart:math Random — deterministic on every CI run, re-seedable by env var
// (ZURAFFA_PROPERTY_SEED) when hunting a failing case locally.
//
// Generators produce JSON-compatible values only (the round-trip targets are
// JSON codecs): null/bool/int/double/String/List/Map. Strings stay on the BMP
// plus one deliberate astral sample so surrogates exercise jsonEncode.
//
// A property failure aborts the loop with the trial number and seed in the
// message — reproducing a failure is `ZURAFFA_PROPERTY_SEED=<seed> dart test
// test/property/<file>` plus the printed trial index.
library;

import 'dart:math';
import 'dart:io' show Platform, stderr;

/// Default seed — fixed so the suite is CI-stable (no flaky "passed last
/// time"). Override locally with ZURAFFA_PROPERTY_SEED to search for new
/// counterexamples; CI always runs the committed seed.
int get defaultSeed {
  final raw = Platform.environment['ZURAFFA_PROPERTY_SEED'];
  if (raw == null) return 20260131;
  return int.tryParse(raw) ?? 20260131;
}

/// Runs [property] [iterations] times against a fresh seeded [Random].
///
/// Every failure is rethrown with the trial index and seed appended so the
/// exact counterexample is reproducible from the failure message alone.
void check(
  String property,
  void Function(Random rnd, int trial) property_, {
  int iterations = 200,
  int? seed,
}) {
  final effectiveSeed = seed ?? defaultSeed;
  final rnd = Random(effectiveSeed);
  for (var trial = 1; trial <= iterations; trial++) {
    try {
      property_(rnd, trial);
    } on Object {
      stderr.writeln(
        'property "$property" failed at trial $trial/$iterations '
        '(seed: $effectiveSeed — reproduce with '
        'ZURAFFA_PROPERTY_SEED=$effectiveSeed)',
      );
      rethrow;
    }
  }
}

/// Uniform int in [min, max] inclusive.
int intBetween(Random rnd, int min, int max) {
  if (max <= min) return min;
  return min + rnd.nextInt(max - min + 1);
}

/// Random printable string, biased toward ASCII identifiers with occasional
/// unicode (incl. one astral-plane char) and empty strings mixed in.
final _stringAlphabet =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-./: ';
const _unicodeSamples = ['é', '日', '⚔', '𝕏', ' ', 'Ø'];

String randomString(Random rnd, {int maxLength = 16, bool allowEmpty = true}) {
  final mode = rnd.nextInt(10);
  if (mode == 0 && allowEmpty) return '';
  if (mode == 1) return _unicodeSamples[rnd.nextInt(_unicodeSamples.length)];
  final length = intBetween(rnd, 1, maxLength);
  final buffer = StringBuffer();
  for (var i = 0; i < length; i++) {
    if (rnd.nextInt(12) == 0) {
      buffer.write(_unicodeSamples[rnd.nextInt(_unicodeSamples.length)]);
    } else {
      buffer.write(_stringAlphabet[rnd.nextInt(_stringAlphabet.length)]);
    }
  }
  return buffer.toString();
}

/// Non-empty random string — for fields whose codecs reject empty.
String randomNonEmptyString(Random rnd, {int maxLength = 16}) {
  var value = randomString(rnd, maxLength: maxLength, allowEmpty: false);
  while (value.isEmpty) {
    value = randomString(rnd, maxLength: maxLength, allowEmpty: false);
  }
  return value;
}

/// A random JSON-compatible scalar (null/bool/int/double/String).
Object? randomJsonScalar(Random rnd) => switch (rnd.nextInt(6)) {
  0 => null,
  1 => rnd.nextBool(),
  2 => intBetween(rnd, -1000000, 1000000),
  3 => (rnd.nextDouble() * 1000).roundToDouble() / 8,
  4 => randomString(rnd),
  _ => randomString(rnd, maxLength: 4),
};

/// A random JSON value with bounded nesting depth and list/map sizes.
Object? randomJsonValue(Random rnd, {int maxDepth = 3}) {
  if (maxDepth <= 0) return randomJsonScalar(rnd);
  switch (rnd.nextInt(8)) {
    case 0:
      return null;
    case 1:
      return rnd.nextBool();
    case 2:
      return intBetween(rnd, -1000000, 1000000);
    case 3:
      return (rnd.nextDouble() * 1000).roundToDouble() / 8;
    case 4:
    case 5:
      return randomString(rnd);
    case 6:
      final length = intBetween(rnd, 0, 4);
      return [
        for (var i = 0; i < length; i++)
          randomJsonValue(rnd, maxDepth: maxDepth - 1),
      ];
    default:
      final size = intBetween(rnd, 0, 4);
      return {
        for (var i = 0; i < size; i++)
          'k$i${randomString(rnd, maxLength: 4)}': randomJsonValue(
            rnd,
            maxDepth: maxDepth - 1,
          ),
      };
  }
}

/// A random JSON object (always a `Map<String, dynamic>`) with bounded
/// nesting — for fields typed as maps.
Map<String, dynamic> randomJsonObject(Random rnd, {int maxDepth = 2}) {
  final size = intBetween(rnd, 0, 4);
  return {
    for (var i = 0; i < size; i++)
      'k$i${randomString(rnd, maxLength: 4)}': randomJsonValue(
        rnd,
        maxDepth: maxDepth,
      ),
  };
}

/// A random ui/tree+json node map: scalar payload keys plus the conventional
/// `children` list of child node maps (bounded depth/breadth).
Map<String, dynamic> randomUiTreeNode(
  Random rnd, {
  int maxDepth = 4,
  String label = 'n',
}) {
  final node = <String, dynamic>{
    'type': randomNonEmptyString(rnd, maxLength: 8),
    'id': '$label${intBetween(rnd, 0, 9999)}',
    'label': randomString(rnd, maxLength: 12),
  };
  if (rnd.nextInt(5) == 0) {
    node['payload'] = randomJsonValue(rnd, maxDepth: 2);
  }
  if (maxDepth > 1 && rnd.nextInt(4) != 0) {
    final childCount = intBetween(rnd, 0, 3);
    node['children'] = [
      for (var i = 0; i < childCount; i++)
        randomUiTreeNode(rnd, maxDepth: maxDepth - 1, label: '$label$i.'),
    ];
  }
  return node;
}

/// A random UTC-or-local DateTime with millisecond precision (ISO-8601
/// round-trips preserve milliseconds exactly for both UTC and local).
///
/// Built as seconds (within Random.nextInt's 2^32 bound) + fractional
/// milliseconds — years 2000..2100.
DateTime randomDateTime(Random rnd) {
  final seconds = intBetween(rnd, 946684800, 4102444799);
  final millis = seconds * 1000 + intBetween(rnd, 0, 999);
  final isUtc = rnd.nextBool();
  return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: isUtc);
}

/// A random shuffled list of [length] bools with exactly [trues] true.
List<bool> randomOutcomeList(Random rnd, int length, int trues) {
  final outcomes = List<bool>.generate(length, (i) => i < trues);
  for (var i = length - 1; i > 0; i--) {
    final j = rnd.nextInt(i + 1);
    final tmp = outcomes[i];
    outcomes[i] = outcomes[j];
    outcomes[j] = tmp;
  }
  return outcomes;
}
