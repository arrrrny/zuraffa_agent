// Issue #138 — TokenEstimator contract tests.
//
// Covers:
//  - the TokenEstimator interface (text / image / message estimation)
//  - HeuristicTokenEstimator: the default ~4-chars-per-token heuristic
//  - TiktokenEstimator: an optional byte-level BPE counter consuming a
//    tiktoken-format rank table (cl100k_base `.tiktoken` line format)

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/token_estimator.dart';
import 'package:zuraffa_agent/src/types.dart';

void main() {
  group('TokenEstimator — HeuristicTokenEstimator (default)', () {
    test('estimateText counts ~4 chars per token, ceiling', () {
      const estimator = HeuristicTokenEstimator();
      expect(estimator.estimateText(''), 0);
      expect(estimator.estimateText('abcd'), 1);
      expect(estimator.estimateText('abcde'), 2);
      expect(estimator.estimateText('abcdefgh'), 2);
      expect(estimator.estimateText('a' * 401), 101);
    });

    test('estimateImage defaults to a flat conservative 1024 tokens', () {
      const estimator = HeuristicTokenEstimator();
      expect(
        estimator.estimateImage(
          const ImageBlock(data: 'aGVsbG8=', mimeType: 'image/png'),
        ),
        1024,
      );
    });

    test('estimateImage honors a custom tokensPerImage', () {
      const estimator = HeuristicTokenEstimator(tokensPerImage: 100);
      expect(
        estimator.estimateImage(
          const ImageBlock(data: 'x', mimeType: 'image/jpeg'),
        ),
        100,
      );
    });

    test('estimateMessages sums text blocks and tool results', () {
      const estimator = HeuristicTokenEstimator();
      final messages = <AgentMessage>[
        UserMessage.text('abcd'), // 1
        AssistantMessage(content: const [TextBlock('abcdefgh')]), // 2
        ToolResultMessage(
          toolCallId: 'c1',
          toolName: 't',
          content: 'abcdabcd', // 2
        ),
      ];
      expect(estimator.estimateMessages(messages), 5);
    });

    test('estimateMessages counts image blocks via tokensPerImage', () {
      const estimator = HeuristicTokenEstimator(tokensPerImage: 50);
      final messages = <AgentMessage>[
        UserMessage(
          content: [
            const TextBlock('abcd'), // 1
            const ImageBlock(data: 'aGVsbG8=', mimeType: 'image/png'), // 50
          ],
        ),
      ];
      expect(estimator.estimateMessages(messages), 51);
    });

    test('estimateMessages: empty transcript costs nothing', () {
      const estimator = HeuristicTokenEstimator();
      expect(estimator.estimateMessages(const []), 0);
    });
  });

  group('TokenEstimator — TiktokenEstimator (byte-level BPE)', () {
    // Tiny rank table where "hello" merges into exactly one token and
    // " world" into exactly one. Every intermediate merge is present so the
    // lowest-rank-first BPE loop can rebuild each token from its bytes.
    Map<String, int> tinyRanks() {
      final ranks = <String, int>{};
      var rank = 0;
      void add(String token) {
        ranks[token] = rank++;
      }

      // Single bytes first.
      add('h');
      add('e');
      add('l');
      add('o');
      add('w');
      add('r');
      add('d');
      // "hello" merge chain: ll, he, hell, hello.
      add('ll');
      add('he');
      add('hell');
      add('hello');
      // " world" merge chain: or, wor, worl, world, ' world'.
      add('or');
      add('wor');
      add('worl');
      add('world');
      add(' world');
      return ranks;
    }

    test('estimateText: a fully merged token counts as one', () {
      final estimator = TiktokenEstimator(ranks: tinyRanks());
      expect(estimator.estimateText('hello'), 1);
    });

    test('estimateText: whitespace-led pieces merge like tiktoken', () {
      final estimator = TiktokenEstimator(ranks: tinyRanks());
      expect(estimator.estimateText('hello world'), 2);
    });

    test('estimateText: unknown bytes fall back per UTF-8 byte', () {
      final estimator = TiktokenEstimator(ranks: tinyRanks());
      // 'µ' encodes to 2 UTF-8 bytes and is absent from the rank table.
      expect(estimator.estimateText('µ'), 2);
    });

    test('estimateText: empty text is free', () {
      final estimator = TiktokenEstimator(ranks: tinyRanks());
      expect(estimator.estimateText(''), 0);
    });

    test(
      'load() parses the tiktoken line format (base64 token + rank)',
      () async {
        final dir = Directory.systemTemp.createTempSync('zfa_tiktoken');
        addTearDown(() => dir.delete(recursive: true));
        final file = File('${dir.path}/tiny.tiktoken');
        file.writeAsStringSync(
          [
            for (final entry in tinyRanks().entries)
              '${base64Encode(utf8.encode(entry.key))} ${entry.value}',
          ].join('\n'),
        );

        final estimator = await TiktokenEstimator.load(file.path);
        expect(estimator.estimateText('hello'), 1);
        expect(estimator.estimateText('hello world'), 2);
      },
    );

    test('satisfies the TokenEstimator interface for messages and images', () {
      final TokenEstimator estimator = TiktokenEstimator(ranks: tinyRanks());
      expect(estimator.estimateMessages([UserMessage.text('hello world')]), 2);
      expect(
        estimator.estimateMessages([
          UserMessage(
            content: [
              const TextBlock('hello'),
              const ImageBlock(data: 'x', mimeType: 'image/png'),
            ],
          ),
        ]),
        1 + 1024, // text + default flat image cost
      );
    });

    test(
      'at maxPieceBytes the merge loop still runs, above it bytes count',
      () {
        final estimator = TiktokenEstimator(ranks: tinyRanks());
        // 4096 bytes: at the cap, the merge loop runs — 'hello' merges
        // into one token, the unmergeable 'a' run stays one token per byte.
        expect(estimator.estimateText('hello' + 'a' * 4091), 1 + 4091);
        // 4097 bytes: above the cap, every byte counts — no merge scan.
        expect(estimator.estimateText('hello' + 'a' * 4092), 4097);
      },
    );

    test(
      'a long unbroken run (base64 payload, hash) is counted without stalling',
      () {
        final estimator = TiktokenEstimator(ranks: tinyRanks());
        final stopwatch = Stopwatch()..start();
        // 140k chars of unbroken alphanumerics = ONE pre-tokenized piece,
        // far above the cap: the pre-flight must not scan it quadratically.
        final estimate = estimator.estimateText('aGVsbG8' * 20000);
        stopwatch.stop();
        expect(estimate, 140000); // conservative per-byte count
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      },
    );

    test('repeated pieces are memoized to the same count', () {
      final estimator = TiktokenEstimator(ranks: tinyRanks());
      // 'hello' merges to one token, ' world' to one, and ' hello' keeps
      // its leading space as a separate byte-token (no ' hello' rank).
      const text = 'hello world hello world';
      expect(estimator.estimateText(text), 5);
      // Second pass over identical pieces (the pre-flight re-estimates the
      // whole transcript every turn) must agree through the cache.
      expect(estimator.estimateText(text), 5);
    });
  });
}
