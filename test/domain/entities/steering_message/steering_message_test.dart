// Spec 081 (issue arrrrny/zuraffa_agent#92) — R1 Steering Message value
// object: JSON contract & equality. TDD cycle: RED (characterization —
// the implementation pre-existed at branch creation) → GREEN →
// MUTATIONS → GATES → verification.md.
//
// Coverage (specs/081-steering-message/tdd/test-list.md):
// - Group A (U1–U3):  round-trip — `toJson` → `fromJson` produces an
//   equal message; `toJson` shape is exactly three keys.
// - Group B (U4–U10): typed ArgumentError on every malformed-input
//   variant (missing key, wrong type, unparseable timestamp).
// - Group C (U11–U16): equality — `==` over all three fields;
//   `hashCode` agrees; identity short-circuits.
// - Group D (U17–U22): edge cases — empty content, unicode, non-UTC,
//   microsecond precision, large payload.
// - Group E (U23):     toString pin — includes type name + id; long
//   content truncated.
//
// Lives in the conventional test/domain/entities/<entity>/ mirror of
// lib/src/domain/entities/<entity>/, matching the existing
// steering_queue/steering_queue_test.dart pattern.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/steering_message/steering_message.dart';

void main() {
  const groupName = 'spec 081 — SteeringMessage';

  group(groupName, () {
    // ----------------------------------------------------------------
    // Group A — round-trip (FR-002 / FR-003)
    // ----------------------------------------------------------------
    group('round-trip', () {
      test('U1: arbitrary values round-trip losslessly', () {
        final original = SteeringMessage(
          id: 'msg-001',
          content: 'please focus on the security review',
          injectedAt: DateTime.utc(2026, 8, 29, 12, 34, 56, 789, 123),
        );

        final json = original.toJson();
        final rebuilt = SteeringMessage.fromJson(json);

        expect(rebuilt == original, isTrue);
        expect(rebuilt.id, original.id);
        expect(rebuilt.content, original.content);
        expect(rebuilt.injectedAt, original.injectedAt);
      });

      test('U2: toJson shape has exactly three keys', () {
        final msg = SteeringMessage(
          id: 'x',
          content: 'y',
          injectedAt: DateTime.utc(2026, 1, 1),
        );

        final json = msg.toJson();

        expect(json.keys.toSet(), {'id', 'content', 'injectedAt'});
      });

      test('U3: toJson injectedAt is ISO-8601 parseable', () {
        final msg = SteeringMessage(
          id: 'x',
          content: 'y',
          injectedAt: DateTime.utc(2026, 1, 1, 12, 0, 0),
        );

        final json = msg.toJson();
        final ts = json['injectedAt'] as String;

        // DateTime.parse handles ISO-8601 strings.
        final parsed = DateTime.parse(ts);
        expect(parsed, msg.injectedAt);
      });
    });

    // ----------------------------------------------------------------
    // Group B — typed ArgumentError on malformed input (FR-004)
    // ----------------------------------------------------------------
    group('typed errors', () {
      test('U4: missing id throws ArgumentError naming id', () {
        const json = <String, dynamic>{
          'content': 'hello',
          'injectedAt': '2026-08-29T12:00:00.000Z',
        };

        expect(
          () => SteeringMessage.fromJson(json),
          throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'id')),
        );
      });

      test('U5: non-string id throws ArgumentError naming id', () {
        final json = <String, dynamic>{
          'id': 42,
          'content': 'hello',
          'injectedAt': '2026-08-29T12:00:00.000Z',
        };

        expect(
          () => SteeringMessage.fromJson(json),
          throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'id')),
        );
      });

      test('U6: missing content throws ArgumentError naming content', () {
        const json = <String, dynamic>{
          'id': 'msg-1',
          'injectedAt': '2026-08-29T12:00:00.000Z',
        };

        expect(
          () => SteeringMessage.fromJson(json),
          throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'content')),
        );
      });

      test('U7: non-string content throws ArgumentError naming content', () {
        final json = <String, dynamic>{
          'id': 'msg-1',
          'content': <String, dynamic>{'nested': 'object'},
          'injectedAt': '2026-08-29T12:00:00.000Z',
        };

        expect(
          () => SteeringMessage.fromJson(json),
          throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'content')),
        );
      });

      test('U8: missing injectedAt throws ArgumentError naming injectedAt', () {
        const json = <String, dynamic>{
          'id': 'msg-1',
          'content': 'hello',
        };

        expect(
          () => SteeringMessage.fromJson(json),
          throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'injectedAt')),
        );
      });

      test('U9: non-string injectedAt throws ArgumentError naming injectedAt', () {
        final json = <String, dynamic>{
          'id': 'msg-1',
          'content': 'hello',
          'injectedAt': 12345,
        };

        expect(
          () => SteeringMessage.fromJson(json),
          throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'injectedAt')),
        );
      });

      test('U10: unparseable injectedAt throws ArgumentError naming injectedAt', () {
        const json = <String, dynamic>{
          'id': 'msg-1',
          'content': 'hello',
          'injectedAt': 'not-a-timestamp',
        };

        expect(
          () => SteeringMessage.fromJson(json),
          throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'injectedAt')),
        );
      });
    });

    // ----------------------------------------------------------------
    // Group C — equality (FR-005)
    // ----------------------------------------------------------------
    group('equality', () {
      final ts = DateTime.utc(2026, 8, 29, 12, 0, 0);

      test('U11: equal messages are ==', () {
        final a = SteeringMessage(id: 'm', content: 'c', injectedAt: ts);
        final b = SteeringMessage(id: 'm', content: 'c', injectedAt: ts);

        expect(a == b, isTrue);
        expect(b == a, isTrue);
      });

      test('U12: differing id breaks ==', () {
        final a = SteeringMessage(id: 'm1', content: 'c', injectedAt: ts);
        final b = SteeringMessage(id: 'm2', content: 'c', injectedAt: ts);

        expect(a == b, isFalse);
      });

      test('U13: differing content breaks ==', () {
        final a = SteeringMessage(id: 'm', content: 'c1', injectedAt: ts);
        final b = SteeringMessage(id: 'm', content: 'c2', injectedAt: ts);

        expect(a == b, isFalse);
      });

      test('U14: differing injectedAt breaks ==', () {
        final a = SteeringMessage(
            id: 'm', content: 'c', injectedAt: ts);
        final b = SteeringMessage(
            id: 'm', content: 'c', injectedAt: ts.add(const Duration(seconds: 1)));

        expect(a == b, isFalse);
      });

      test('U15: hashCode agrees with ==', () {
        final a = SteeringMessage(id: 'm', content: 'c', injectedAt: ts);
        final b = SteeringMessage(id: 'm', content: 'c', injectedAt: ts);
        final c = SteeringMessage(id: 'other', content: 'c', injectedAt: ts);

        expect(a == b, isTrue);
        expect(a.hashCode, b.hashCode);
        expect(a == c, isFalse);
      });

      test('U16: identity short-circuits', () {
        final msg = SteeringMessage(id: 'm', content: 'c', injectedAt: ts);
        // ignore: unnecessary_type_check
        expect(identical(msg, msg), isTrue);
        expect(msg == msg, isTrue);
      });
    });

    // ----------------------------------------------------------------
    // Group D — edge cases (FR-006)
    // ----------------------------------------------------------------
    group('edge cases', () {
      test('U17: empty content round-trips', () {
        final original = SteeringMessage(
          id: 'msg-empty',
          content: '',
          injectedAt: DateTime.utc(2026, 1, 1),
        );

        final rebuilt = SteeringMessage.fromJson(original.toJson());

        expect(rebuilt == original, isTrue);
        expect(rebuilt.content, isEmpty);
      });

      test('U18: unicode id round-trips', () {
        final original = SteeringMessage(
          id: '消息-🔑-123',
          content: 'hello',
          injectedAt: DateTime.utc(2026, 1, 1),
        );

        final rebuilt = SteeringMessage.fromJson(original.toJson());

        expect(rebuilt == original, isTrue);
        expect(rebuilt.id, '消息-🔑-123');
      });

      test('U19: unicode content round-trips (Chinese, emoji, RTL)', () {
        final original = SteeringMessage(
          id: 'msg-uni',
          content: '中文测试 🎉 مرحبا بالعالم',
          injectedAt: DateTime.utc(2026, 1, 1),
        );

        final rebuilt = SteeringMessage.fromJson(original.toJson());

        expect(rebuilt == original, isTrue);
        expect(rebuilt.content, '中文测试 🎉 مرحبا بالعالم');
      });

      test('U20: non-UTC timestamp round-trips', () {
        // DateTime.parse preserves the timezone offset in the string
        // representation, but toIso8601String() always uses UTC. We
        // test that a non-UTC DateTime round-trips to an equal DateTime.
        final original = SteeringMessage(
          id: 'msg-tz',
          content: 'hello',
          // Construct a non-UTC time: 2026-08-29 14:00:00 +02:00
          injectedAt: DateTime(2026, 8, 29, 14, 0, 0).subtract(
            const Duration(hours: 2),
          ),
        );

        final rebuilt = SteeringMessage.fromJson(original.toJson());

        // Two DateTimes are equal iff their instants are equal (DateTime.==
        // compares millisecondsSinceEpoch, not the timezone label).
        expect(rebuilt.injectedAt == original.injectedAt, isTrue);
        expect(rebuilt == original, isTrue);
      });

      test('U21: microsecond precision round-trips', () {
        final original = SteeringMessage(
          id: 'msg-us',
          content: 'hello',
          injectedAt: DateTime.utc(2026, 8, 29, 12, 34, 56, 789, 123),
        );

        final rebuilt = SteeringMessage.fromJson(original.toJson());

        expect(rebuilt == original, isTrue);
        expect(rebuilt.injectedAt.microsecond, 123);
      });

      test('U22: large content (>= 10 KB) round-trips', () {
        final big = 'a' * 10240; // 10 KB of 'a'
        final original = SteeringMessage(
          id: 'msg-big',
          content: big,
          injectedAt: DateTime.utc(2026, 1, 1),
        );

        final rebuilt = SteeringMessage.fromJson(original.toJson());

        expect(rebuilt == original, isTrue);
        expect(rebuilt.content.length, 10240);
      });
    });

    // ----------------------------------------------------------------
    // Group E — toString pin (FR-007)
    // ----------------------------------------------------------------
    group('toString', () {
      test('U23: includes type name and id; long content truncated', () {
        final msg = SteeringMessage(
          id: 'msg-1',
          content: 'a' * 100,  // 100 chars — well over the 40-char truncation
          injectedAt: DateTime.utc(2026, 1, 1),
        );

        final s = msg.toString();

        expect(s, contains('SteeringMessage'));
        expect(s, contains('msg-1'));
        // Truncation marker present (…).
        expect(s, contains('…'));
        // The full 100-char content is NOT present (truncated).
        expect(s.contains('a' * 100), isFalse);
      });
    });
  });
}
