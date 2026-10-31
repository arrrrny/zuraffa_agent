// Tests for the engine CancellationToken (issue #140, spec 072 update).
//
// Cancellation in the engine is COOPERATIVE: an owner signals the token and
// the bearer (a mission loop, a swarm member) observes it at its own
// checkpoints. These tests pin the token's own contract: signal semantics,
// idempotence, and the whenCancelled await path.

import 'dart:async';

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/engine/cancellation_token.dart';

void main() {
  group('CancellationToken', () {
    test('starts uncancelled', () {
      final token = CancellationToken();

      expect(token.isCancelled, isFalse);
    });

    test('cancel() flips isCancelled and completes whenCancelled', () async {
      final token = CancellationToken();
      var awaited = false;
      unawaited(
        token.whenCancelled.then<void>((_) {
          awaited = true;
        }),
      );

      expect(token.isCancelled, isFalse);
      token.cancel();

      expect(token.isCancelled, isTrue);
      await token.whenCancelled;
      expect(awaited, isTrue);
    });

    test('cancel() is idempotent — repeated calls are no-ops', () {
      final token = CancellationToken();

      token.cancel();
      token.cancel();
      token.cancel();

      expect(token.isCancelled, isTrue);
    });

    test('whenCancelled resolves immediately for late awaiters', () async {
      final token = CancellationToken();
      token.cancel();

      // Must not hang: a bearer attaching after the signal still resolves.
      await token.whenCancelled;

      expect(token.isCancelled, isTrue);
    });

    test('independent tokens do not cross-signal', () async {
      final a = CancellationToken();
      final b = CancellationToken();

      a.cancel();

      expect(a.isCancelled, isTrue);
      expect(b.isCancelled, isFalse);
    });
  });
}
