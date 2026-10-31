// Issue #138 — client-side token counting for pre-flight checks.
//
// Before a turn is sent, MissionRunner estimates the transcript against the
// model's context window (model.contextWindow * 0.8) and triggers the
// ContextCompressor proactively instead of waiting for the provider to
// return a 400 context-overflow error.
//
// Two estimators ship:
//   - HeuristicTokenEstimator — the default. ~4 characters per token for
//     English prose (the same convention estimateContextTokens already uses
//     for compaction). Zero dependencies, deterministic, no assets.
//   - TiktokenEstimator — optional, higher-fidelity. A byte-level BPE
//     counter that consumes a tiktoken rank table (the `.tiktoken` line
//     format used by cl100k_base/o200k_base: `<base64 token> <rank>` per
//     line). Download a rank file from openai/tiktoken and hand it to
//     TiktokenEstimator.load. Pre-tokenization is a simplified GPT-style
//     pattern, so counts are near-tiktoken, not bit-identical.

import 'dart:convert';
import 'dart:io';

import '../types.dart';

/// Estimates how many model tokens a payload will consume.
///
/// Implementations must be pure and synchronous: the pre-flight check runs
/// before every turn and must never do I/O on the hot path (load rank
/// tables up front — see [TiktokenEstimator.load]).
abstract interface class TokenEstimator {
  /// Estimated token count for a plain-text payload (empty text is 0).
  int estimateText(String text);

  /// Estimated token count for one image block. Images are not tokenized
  /// by any shipped estimator; implementations return a flat conservative
  /// cost so an image-bearing transcript cannot slip under the estimate.
  int estimateImage(ImageBlock image);

  /// Estimated token count for a full message list (blocks summed).
  int estimateMessages(List<AgentMessage> messages);
}

/// Block/message walk shared by every [TokenEstimator]: subclasses supply
/// the text and image primitives, this class turns a transcript into
/// primitive calls.
abstract class TokenEstimatorBase implements TokenEstimator {
  const TokenEstimatorBase();

  @override
  int estimateMessages(List<AgentMessage> messages) {
    var total = 0;
    for (final message in messages) {
      switch (message) {
        case UserMessage(:final content) || AssistantMessage(:final content):
          for (final block in content) {
            total += _blockCost(block);
          }
        case ToolResultMessage():
          total += estimateText(message.content);
        case CustomMessage():
          total += estimateText(
            '[custom:${message.messageType}] ${jsonEncode(message.payload)}',
          );
      }
    }
    return total;
  }

  int _blockCost(ContentBlock block) => switch (block) {
    TextBlock(:final text) => estimateText(text),
    ImageBlock() => estimateImage(block),
    // Binary payloads arrive base64-encoded; ~4 chars/token over the
    // encoded payload is a conservative stand-in until a provider-specific
    // binary tokenizer exists.
    AudioBlock(:final data) => estimateText(data),
    DocumentBlock(:final data) => estimateText(data),
    ToolCallBlock(:final arguments) => estimateText(jsonEncode(arguments)),
    ThinkingBlock(:final thinking) => estimateText(thinking),
  };
}

/// The default estimator: ~4 characters per token, ceiling.
///
/// Images and other binary blocks cost [tokensPerImage] (default 1024) —
/// a flat conservative placeholder in place of provider-specific image
/// tokenization formulas.
class HeuristicTokenEstimator extends TokenEstimatorBase {
  const HeuristicTokenEstimator({
    this.charsPerToken = 4,
    this.tokensPerImage = defaultTokensPerImage,
  }) : assert(charsPerToken > 0),
       assert(tokensPerImage >= 0);

  /// Shared flat image cost for estimators that do not tokenize pixels.
  static const int defaultTokensPerImage = 1024;

  final int charsPerToken;
  final int tokensPerImage;

  @override
  int estimateText(String text) =>
      text.isEmpty ? 0 : (text.length / charsPerToken).ceil();

  @override
  int estimateImage(ImageBlock image) => tokensPerImage;
}

/// Optional tiktoken-equivalent: byte-level BPE over a rank table.
///
/// [ranks] maps token byte-strings (chars 0–255 per byte, the same encoding
/// tiktoken uses internally) to merge priority — lower rank merges first.
/// Load a real table with [load]:
/// ```dart
/// final estimator = await TiktokenEstimator.load('cl100k_base.tiktoken');
/// ```
/// Pre-tokenization uses a simplified GPT-style pattern (word pieces keep
/// their leading space; digits are not re-chunked), so counts track
/// tiktoken closely for English prose but are not bit-identical.
class TiktokenEstimator extends TokenEstimatorBase {
  TiktokenEstimator({
    required Map<String, int> ranks,
    this.tokensPerImage = HeuristicTokenEstimator.defaultTokensPerImage,
    RegExp? pattern,
  }) : _ranks = Map.of(ranks),
       _pattern =
           pattern ??
           RegExp(r' ?[\p{L}\p{N}]+| ?[^\s\p{L}\p{N}]+|\s+', unicode: true) {
    for (final token in _ranks.keys) {
      for (var i = 0; i < token.length; i++) {
        if (token.codeUnitAt(i) > 255) {
          throw ArgumentError.value(
            token,
            'ranks',
            'token keys must be byte strings (code units 0-255)',
          );
        }
      }
    }
  }

  /// Parses a tiktoken `.tiktoken` file: one `<base64 token> <rank>` pair
  /// per line, `#`-prefixed comments allowed (cl100k_base / o200k_base
  /// format).
  static Future<TiktokenEstimator> load(
    String path, {
    int tokensPerImage = HeuristicTokenEstimator.defaultTokensPerImage,
  }) async {
    final ranks = <String, int>{};
    final lines = await File(path).readAsLines();
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final split = trimmed.lastIndexOf(' ');
      if (split <= 0) continue;
      final bytes = base64Decode(trimmed.substring(0, split));
      final rank = int.tryParse(trimmed.substring(split + 1));
      if (rank == null) continue;
      ranks[String.fromCharCodes(bytes)] = rank;
    }
    if (ranks.isEmpty) {
      throw ArgumentError.value(path, 'path', 'no tiktoken ranks parsed');
    }
    return TiktokenEstimator(ranks: ranks, tokensPerImage: tokensPerImage);
  }

  final Map<String, int> _ranks;
  final RegExp _pattern;
  final int tokensPerImage;

  /// Pieces above this many UTF-8 bytes skip the merge loop and fall back
  /// to one token per byte. The merge scan is quadratic per piece (every
  /// adjacent pair is rescanned with a string allocation per pair, per
  /// merge iteration), and a long unbroken run — a base64 image payload
  /// inside a tool result, a hash, an id list — is ONE pre-tokenized
  /// piece: a 100KB such piece would otherwise stall the pre-flight for
  /// minutes per turn (issue #138 review). The fallback is the same
  /// conservative count the loop already gives bytes that never merge,
  /// and the estimator's contract is estimation, not exactness.
  static const int maxPieceBytes = 4096;

  /// Memoized per-piece counts (issue #138 review). Only pieces under
  /// [maxPieceBytes] are cached — large pieces never enter the merge loop
  /// — and the cache is cleared when full, so repeated transcript content
  /// (identical tool outputs, boilerplate) costs one lookup per turn
  /// instead of a full re-scan, without unbounded growth across a mission.
  final Map<String, int> _pieceCache = {};
  static const int maxCachedPieces = 1024;

  @override
  int estimateText(String text) {
    if (text.isEmpty) return 0;
    var total = 0;
    for (final match in _pattern.allMatches(text)) {
      total += _pieceTokenCount(match[0]!);
    }
    return total;
  }

  @override
  int estimateImage(ImageBlock image) => tokensPerImage;

  /// Counts one pre-tokenized piece, memoized (see [_pieceCache]).
  int _pieceTokenCount(String piece) {
    final cached = _pieceCache[piece];
    if (cached != null) return cached;
    final bytes = utf8.encode(piece);
    final count = bytes.isEmpty
        ? 0
        : bytes.length > maxPieceBytes
        ? bytes.length
        : _mergePiece(bytes);
    if (bytes.length <= maxPieceBytes) {
      if (_pieceCache.length >= maxCachedPieces) _pieceCache.clear();
      _pieceCache[piece] = count;
    }
    return count;
  }

  /// Runs the BPE merge loop over one pre-tokenized piece's UTF-8 bytes.
  ///
  /// Adjacent parts merge lowest-rank-first while any adjacent pair is in
  /// the rank table; parts that can never merge fall back to one token per
  /// byte, mirroring tiktoken's behaviour on unknown bytes.
  int _mergePiece(List<int> bytes) {
    var parts = [
      for (final byte in bytes) [byte],
    ];
    while (parts.length > 1) {
      var bestRank = -1;
      var bestIndex = -1;
      for (var i = 0; i < parts.length - 1; i++) {
        final rank =
            _ranks[String.fromCharCodes([...parts[i], ...parts[i + 1]])];
        if (rank != null && (bestRank < 0 || rank < bestRank)) {
          bestRank = rank;
          bestIndex = i;
        }
      }
      if (bestIndex < 0) break;
      parts = [
        ...parts.sublist(0, bestIndex),
        [...parts[bestIndex], ...parts[bestIndex + 1]],
        ...parts.sublist(bestIndex + 2),
      ];
    }
    var total = 0;
    for (final part in parts) {
      total += _ranks.containsKey(String.fromCharCodes(part)) ? 1 : part.length;
    }
    return total;
  }
}
