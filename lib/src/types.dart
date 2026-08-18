// Ported from pi_agent (~/Developer/pi/pi_agent, branch 001-dart-agent-package).
// Source licensed BSD-3-Clause (ZikZak AI); modifications licensed MIT under
// zuraffa_agent. See NOTICE.
/// Core entity types for the zuraffa_agent engine.
///
/// Defines the sealed class hierarchies ([AgentMessage], [ContentBlock],
/// [SessionTreeEntry]), enums, support value objects, and the monotonic
/// entry ID generator backing every persisted session entity.
///
/// Deviations from the pi_agent source (per specs/002-state-and-sessions):
/// - loop-runtime types (AgentEvent, AgentState, AgentContext, hook
///   contexts, AgentLoopConfig) are NOT ported — spec 001 owns them;
/// - `typedef AgentTool<TParameters, TDetails> = dynamic` is dropped; the
///   real class in `tools.dart` is the only [AgentTool];
/// - [CompactionEntry] carries a typed [CompactionSummary] (was `String`);
/// - NEW content blocks: [AudioBlock], [DocumentBlock];
/// - all value types implement `==`/`hashCode` for cross-store equivalence.
library;

import 'compaction.dart';

/// Thinking/reasoning level for models that support extended thinking.
enum ThinkingLevel {
  /// No thinking output.
  off,

  /// Minimal thinking.
  minimal,

  /// Low thinking effort.
  low,

  /// Medium thinking effort.
  medium,

  /// High thinking effort.
  high,

  /// Extra-high thinking effort.
  xhigh,
}

/// Tool execution concurrency mode.
enum ToolExecutionMode {
  /// Execute tool calls sequentially, one at a time.
  sequential,

  /// Execute tool calls in parallel using Future.wait.
  parallel,
}

/// Reason the LLM stopped generating.
enum StopReason {
  /// The model finished its response naturally.
  endTurn,

  /// The model hit the maximum token limit.
  maxTokens,

  /// The model requested a tool call.
  toolUse,

  /// The model hit a stop sequence.
  stopSequence,

  /// The model refused to respond.
  refused,
}

/// LLM model descriptor.
///
/// Describes a specific model including its provider, identifier,
/// context window size, and capability flags.
class Model {
  /// Provider name (e.g., 'openai', 'anthropic').
  final String provider;

  /// Model identifier (e.g., 'gpt-4o', 'claude-sonnet-4-20250514').
  final String modelId;

  /// Maximum context window in tokens.
  final int contextWindow;

  /// Whether the model supports image inputs.
  final bool supportsVision;

  /// Whether the model supports extended thinking.
  final bool supportsThinking;

  /// Whether the model supports tool/function calling.
  final bool supportsTools;

  /// Additional provider-specific configuration.
  final Map<String, dynamic>? extra;

  /// Creates a model descriptor.
  const Model({
    required this.provider,
    required this.modelId,
    required this.contextWindow,
    this.supportsVision = false,
    this.supportsThinking = false,
    this.supportsTools = true,
    this.extra,
  });

  @override
  bool operator ==(Object other) =>
      other is Model &&
      other.provider == provider &&
      other.modelId == modelId &&
      other.contextWindow == contextWindow &&
      other.supportsVision == supportsVision &&
      other.supportsThinking == supportsThinking &&
      other.supportsTools == supportsTools &&
      _mapEq(other.extra, extra);

  @override
  int get hashCode => Object.hash(provider, modelId, contextWindow,
      supportsVision, supportsThinking, supportsTools);

  @override
  String toString() => 'Model($provider/$modelId)';
}

/// Token usage tracking from an LLM response.
class Usage {
  /// Number of input tokens consumed.
  final int inputTokens;

  /// Number of output tokens generated.
  final int outputTokens;

  /// Tokens used for cache creation (provider-specific).
  final int? cacheCreationInputTokens;

  /// Tokens read from cache (provider-specific).
  final int? cacheReadInputTokens;

  /// Creates a usage record.
  const Usage({
    required this.inputTokens,
    required this.outputTokens,
    this.cacheCreationInputTokens,
    this.cacheReadInputTokens,
  });

  @override
  bool operator ==(Object other) =>
      other is Usage &&
      other.inputTokens == inputTokens &&
      other.outputTokens == outputTokens &&
      other.cacheCreationInputTokens == cacheCreationInputTokens &&
      other.cacheReadInputTokens == cacheReadInputTokens;

  @override
  int get hashCode =>
      Object.hash(inputTokens, outputTokens, cacheCreationInputTokens,
          cacheReadInputTokens);
}

/// A content block within a message.
///
/// Sealed union of every multimodal part a message can carry.
sealed class ContentBlock {
  /// Creates a content block.
  const ContentBlock();
}

/// A text content block.
class TextBlock extends ContentBlock {
  /// The text content.
  final String text;

  /// Creates a text block.
  const TextBlock(this.text);

  @override
  bool operator ==(Object other) => other is TextBlock && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'TextBlock($text)';
}

/// An image content block encoded as base64.
class ImageBlock extends ContentBlock {
  /// Base64-encoded image data.
  final String base64Data;

  /// MIME type of the image (e.g., 'image/png').
  final String mediaType;

  /// Creates an image block.
  const ImageBlock({required this.base64Data, required this.mediaType});

  @override
  bool operator ==(Object other) =>
      other is ImageBlock &&
      other.base64Data == base64Data &&
      other.mediaType == mediaType;

  @override
  int get hashCode => Object.hash(base64Data, mediaType);
}

/// An audio content block encoded as base64.
class AudioBlock extends ContentBlock {
  /// Base64-encoded audio data.
  final String base64Data;

  /// MIME type of the audio (e.g., 'audio/wav').
  final String mediaType;

  /// Optional transcript of the audio.
  final String? transcript;

  /// Creates an audio block.
  const AudioBlock({
    required this.base64Data,
    required this.mediaType,
    this.transcript,
  });

  @override
  bool operator ==(Object other) =>
      other is AudioBlock &&
      other.base64Data == base64Data &&
      other.mediaType == mediaType &&
      other.transcript == transcript;

  @override
  int get hashCode => Object.hash(base64Data, mediaType, transcript);
}

/// A document content block encoded as base64.
class DocumentBlock extends ContentBlock {
  /// MIME type of the document (e.g., 'application/pdf').
  final String mediaType;

  /// Base64-encoded document data.
  final String base64Data;

  /// Optional document title.
  final String? title;

  /// Creates a document block.
  const DocumentBlock({
    required this.mediaType,
    required this.base64Data,
    this.title,
  });

  @override
  bool operator ==(Object other) =>
      other is DocumentBlock &&
      other.mediaType == mediaType &&
      other.base64Data == base64Data &&
      other.title == title;

  @override
  int get hashCode => Object.hash(mediaType, base64Data, title);
}

/// A tool call within an assistant message's content.
class ToolCallBlock extends ContentBlock {
  /// Unique identifier for this tool call.
  final String id;

  /// Name of the tool to invoke.
  final String name;

  /// Arguments for the tool call as a JSON-compatible map.
  final Map<String, dynamic> arguments;

  /// Creates a tool call block.
  const ToolCallBlock({
    required this.id,
    required this.name,
    required this.arguments,
  });

  @override
  bool operator ==(Object other) =>
      other is ToolCallBlock &&
      other.id == id &&
      other.name == name &&
      _mapEq(other.arguments, arguments);

  @override
  int get hashCode => Object.hash(id, name);
}

/// A thinking/reasoning content block.
class ThinkingBlock extends ContentBlock {
  /// The thinking text content.
  final String text;

  /// Creates a thinking block.
  const ThinkingBlock(this.text);

  @override
  bool operator ==(Object other) => other is ThinkingBlock && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

/// Agent message discriminated union.
///
/// Sealed hierarchy representing all message types in an agent conversation.
sealed class AgentMessage {
  /// Creates an agent message.
  const AgentMessage();
}

/// A message from the user.
class UserMessage extends AgentMessage {
  /// Content blocks in this message.
  final List<ContentBlock> content;

  /// Creates a user message.
  UserMessage({required this.content});

  /// Convenience constructor from a plain text string.
  UserMessage.text(String text) : content = [TextBlock(text)];

  @override
  bool operator ==(Object other) =>
      other is UserMessage && _blockListEq(other.content, content);

  @override
  int get hashCode => Object.hashAll(content);
}

/// A message from the assistant (LLM).
class AssistantMessage extends AgentMessage {
  /// Optional message ID from the provider.
  final String? id;

  /// Content blocks (mixed [TextBlock], [ToolCallBlock], [ThinkingBlock]).
  final List<ContentBlock> content;

  /// Reason the assistant stopped generating.
  final StopReason? stopReason;

  /// Token usage for this response.
  final Usage? usage;

  /// Creates an assistant message.
  AssistantMessage({
    this.id,
    required this.content,
    this.stopReason,
    this.usage,
  });

  /// Extracts all text content from this message.
  String get text => content.whereType<TextBlock>().map((b) => b.text).join();

  /// Extracts all tool call blocks.
  List<ToolCallBlock> get toolCalls =>
      content.whereType<ToolCallBlock>().toList();

  @override
  bool operator ==(Object other) =>
      other is AssistantMessage &&
      other.id == id &&
      other.stopReason == stopReason &&
      other.usage == usage &&
      _blockListEq(other.content, content);

  @override
  int get hashCode => Object.hash(id, stopReason, usage);
}

/// A tool result message returned after tool execution.
class ToolResultMessage extends AgentMessage {
  /// ID of the tool call this result corresponds to.
  final String toolCallId;

  /// Name of the tool that was executed.
  final String toolName;

  /// Result content blocks.
  final List<ContentBlock> content;

  /// Whether the tool execution resulted in an error.
  final bool isError;

  /// Creates a tool result message.
  ToolResultMessage({
    required this.toolCallId,
    required this.toolName,
    required this.content,
    this.isError = false,
  });

  /// Convenience constructor from a plain text string.
  ToolResultMessage.text({
    required this.toolCallId,
    required this.toolName,
    required String text,
    this.isError = false,
  }) : content = [TextBlock(text)];

  @override
  bool operator ==(Object other) =>
      other is ToolResultMessage &&
      other.toolCallId == toolCallId &&
      other.toolName == toolName &&
      other.isError == isError &&
      _blockListEq(other.content, content);

  @override
  int get hashCode => Object.hash(toolCallId, toolName, isError);
}

/// A custom message type for application-specific data.
///
/// Extensibility point: the map payload is intentional and is the documented
/// boundary of the package's no-map-escape rule.
class CustomMessage extends AgentMessage {
  /// The custom message type identifier.
  final String type;

  /// Application-specific data payload.
  final Map<String, dynamic> data;

  /// Display text representation of this message.
  final String display;

  /// Creates a custom message.
  const CustomMessage({
    required this.type,
    required this.data,
    required this.display,
  });

  @override
  bool operator ==(Object other) =>
      other is CustomMessage &&
      other.type == type &&
      other.display == display &&
      _mapEq(other.data, data);

  @override
  int get hashCode => Object.hash(type, display);
}

/// Result from tool execution.
class AgentToolResult<T> {
  /// Content blocks to send back to the LLM.
  final List<ContentBlock> content;

  /// Structured details for UI/logging.
  final T details;

  /// Hint to skip the follow-up LLM call after this batch.
  final bool terminate;

  /// Creates a tool result.
  const AgentToolResult({
    required this.content,
    required this.details,
    this.terminate = false,
  });

  @override
  bool operator ==(Object other) =>
      other is AgentToolResult<T> &&
      other.terminate == terminate &&
      other.details == details &&
      _blockListEq(other.content, content);

  @override
  int get hashCode => Object.hash(terminate, details);
}

/// Session tree entry discriminated union.
///
/// Each entry is an append-only node in the session tree with an ID, a
/// parent reference, and a timestamp.
sealed class SessionTreeEntry {
  /// Unique entry identifier.
  final String id;

  /// Parent entry ID (empty string for root).
  final String parentId;

  /// When this entry was created.
  final DateTime timestamp;

  /// Creates a session tree entry.
  const SessionTreeEntry({
    required this.id,
    required this.parentId,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      other is SessionTreeEntry &&
      other.id == id &&
      other.parentId == parentId &&
      other.timestamp == timestamp &&
      other.runtimeType == runtimeType;

  @override
  int get hashCode => Object.hash(runtimeType, id, parentId, timestamp);
}

/// A message entry in the session tree.
class MessageEntry extends SessionTreeEntry {
  /// Message role: 'user', 'assistant', 'toolResult', or 'custom'.
  final String role;

  /// The message content.
  final AgentMessage message;

  /// Creates a message entry.
  const MessageEntry({
    required super.id,
    required super.parentId,
    required super.timestamp,
    required this.role,
    required this.message,
  });

  @override
  bool operator ==(Object other) =>
      other is MessageEntry &&
      super == other &&
      other.role == role &&
      other.message == message;

  @override
  int get hashCode => Object.hash(super.hashCode, role, message);
}

/// A thinking level change entry.
class ThinkingLevelChangeEntry extends SessionTreeEntry {
  /// New thinking level.
  final ThinkingLevel level;

  /// Creates a thinking level change entry.
  const ThinkingLevelChangeEntry({
    required super.id,
    required super.parentId,
    required super.timestamp,
    required this.level,
  });

  @override
  bool operator ==(Object other) =>
      other is ThinkingLevelChangeEntry && super == other && other.level == level;

  @override
  int get hashCode => Object.hash(super.hashCode, level);
}

/// A model change entry.
class ModelChangeEntry extends SessionTreeEntry {
  /// Provider name.
  final String provider;

  /// New model identifier.
  final String modelId;

  /// Creates a model change entry.
  const ModelChangeEntry({
    required super.id,
    required super.parentId,
    required super.timestamp,
    required this.provider,
    required this.modelId,
  });

  @override
  bool operator ==(Object other) =>
      other is ModelChangeEntry &&
      super == other &&
      other.provider == provider &&
      other.modelId == modelId;

  @override
  int get hashCode => Object.hash(super.hashCode, provider, modelId);
}

/// A compaction summary entry.
class CompactionEntry extends SessionTreeEntry {
  /// Structured summary of the compacted entries.
  final CompactionSummary summary;

  /// ID of the first entry kept after compaction.
  final String firstKeptEntryId;

  /// Token count before compaction.
  final int tokensBefore;

  /// Creates a compaction entry.
  const CompactionEntry({
    required super.id,
    required super.parentId,
    required super.timestamp,
    required this.summary,
    required this.firstKeptEntryId,
    required this.tokensBefore,
  });

  @override
  bool operator ==(Object other) =>
      other is CompactionEntry &&
      super == other &&
      other.summary == summary &&
      other.firstKeptEntryId == firstKeptEntryId &&
      other.tokensBefore == tokensBefore;

  @override
  int get hashCode =>
      Object.hash(super.hashCode, summary, firstKeptEntryId, tokensBefore);
}

/// A branch summary entry.
class BranchSummaryEntry extends SessionTreeEntry {
  /// Summary of the branch.
  final String summary;

  /// Creates a branch summary entry.
  const BranchSummaryEntry({
    required super.id,
    required super.parentId,
    required super.timestamp,
    required this.summary,
  });

  @override
  bool operator ==(Object other) =>
      other is BranchSummaryEntry && super == other && other.summary == summary;

  @override
  int get hashCode => Object.hash(super.hashCode, summary);
}

/// A label entry applied to a target entry.
class LabelEntry extends SessionTreeEntry {
  /// ID of the entry being labeled.
  final String targetId;

  /// Label text.
  final String? label;

  /// Creates a label entry.
  const LabelEntry({
    required super.id,
    required super.parentId,
    required super.timestamp,
    required this.targetId,
    this.label,
  });

  @override
  bool operator ==(Object other) =>
      other is LabelEntry &&
      super == other &&
      other.targetId == targetId &&
      other.label == label;

  @override
  int get hashCode => Object.hash(super.hashCode, targetId, label);
}

/// A custom entry for application-specific data.
///
/// Extensibility point: the map payload is intentional and is the documented
/// boundary of the package's no-map-escape rule.
class CustomEntry extends SessionTreeEntry {
  /// Custom type identifier.
  final String customType;

  /// Application-specific data.
  final Map<String, dynamic>? data;

  /// Creates a custom entry.
  const CustomEntry({
    required super.id,
    required super.parentId,
    required super.timestamp,
    required this.customType,
    this.data,
  });

  @override
  bool operator ==(Object other) =>
      other is CustomEntry &&
      super == other &&
      other.customType == customType &&
      _mapEq(other.data, data);

  @override
  int get hashCode => Object.hash(super.hashCode, customType);
}

/// Session metadata.
class SessionInfo {
  /// Unique session identifier.
  final String id;

  /// Human-readable session name.
  final String name;

  /// When the session was created.
  final DateTime createdAt;

  /// When the session was last updated.
  final DateTime updatedAt;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  /// Creates session info.
  const SessionInfo({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  @override
  bool operator ==(Object other) =>
      other is SessionInfo &&
      other.id == id &&
      other.name == name &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      _mapEq(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(id, name, createdAt, updatedAt);
}

/// Reconstructed session context.
class SessionContext {
  /// Reconstructed messages.
  final List<AgentMessage> messages;

  /// Current thinking level.
  final ThinkingLevel thinkingLevel;

  /// Current model.
  final Model model;

  /// Creates a session context.
  const SessionContext({
    required this.messages,
    required this.thinkingLevel,
    required this.model,
  });

  @override
  bool operator ==(Object other) =>
      other is SessionContext &&
      other.thinkingLevel == thinkingLevel &&
      other.model == model &&
      _msgListEq(other.messages, messages);

  @override
  int get hashCode => Object.hash(thinkingLevel, model);
}

/// Compaction settings.
class CompactionSettings {
  /// Whether compaction is enabled.
  final bool enabled;

  /// Tokens to reserve for the response after compaction.
  final int reserveTokens;

  /// Number of recent tokens to keep during compaction.
  final int keepRecentTokens;

  /// Fraction of the usable window (`contextWindow - reserveTokens`) above
  /// which compaction triggers; 1.0 means trigger once the estimate exceeds
  /// the usable window.
  final double triggerThresholdRatio;

  /// Creates compaction settings.
  const CompactionSettings({
    this.enabled = true,
    this.reserveTokens = 16384,
    this.keepRecentTokens = 20000,
    this.triggerThresholdRatio = 1.0,
  });

  @override
  bool operator ==(Object other) =>
      other is CompactionSettings &&
      other.enabled == enabled &&
      other.reserveTokens == reserveTokens &&
      other.keepRecentTokens == keepRecentTokens &&
      other.triggerThresholdRatio == triggerThresholdRatio;

  @override
  int get hashCode =>
      Object.hash(enabled, reserveTokens, keepRecentTokens, triggerThresholdRatio);
}

/// Skill loaded from a SKILL.md file.
class Skill {
  /// Skill name from YAML frontmatter.
  final String name;

  /// Skill description.
  final String description;

  /// Full SKILL.md body content.
  final String content;

  /// Invocation format string.
  final String? invocation;

  /// Whether this skill is hidden from the system prompt.
  final bool hidden;

  /// File path this skill was loaded from.
  final String sourcePath;

  /// Diagnostics from loading.
  final List<SkillDiagnostic> diagnostics;

  /// Creates a skill.
  const Skill({
    required this.name,
    required this.description,
    required this.content,
    this.invocation,
    this.hidden = false,
    required this.sourcePath,
    this.diagnostics = const [],
  });

  @override
  bool operator ==(Object other) =>
      other is Skill &&
      other.name == name &&
      other.description == description &&
      other.content == content &&
      other.invocation == invocation &&
      other.hidden == hidden &&
      other.sourcePath == sourcePath;

  @override
  int get hashCode =>
      Object.hash(name, description, content, invocation, hidden, sourcePath);
}

/// Diagnostic from skill loading.
class SkillDiagnostic {
  /// Severity level.
  final SkillDiagnosticLevel level;

  /// Diagnostic message.
  final String message;

  /// File path that triggered this diagnostic.
  final String? sourcePath;

  /// Creates a skill diagnostic.
  const SkillDiagnostic({
    required this.level,
    required this.message,
    this.sourcePath,
  });

  @override
  bool operator ==(Object other) =>
      other is SkillDiagnostic &&
      other.level == level &&
      other.message == message &&
      other.sourcePath == sourcePath;

  @override
  int get hashCode => Object.hash(level, message, sourcePath);
}

/// Skill diagnostic severity level.
enum SkillDiagnosticLevel {
  /// Warning - skill loaded but with issues.
  warning,

  /// Error - skill could not be loaded.
  error,
}

/// Prompt template loaded from a .md file.
class PromptTemplate {
  /// Template name.
  final String name;

  /// Template description.
  final String description;

  /// Full template content with placeholders.
  final String content;

  /// Named arguments expected by this template.
  final List<String> args;

  /// File path this template was loaded from.
  final String sourcePath;

  /// Creates a prompt template.
  const PromptTemplate({
    required this.name,
    required this.description,
    required this.content,
    this.args = const [],
    required this.sourcePath,
  });

  @override
  bool operator ==(Object other) =>
      other is PromptTemplate &&
      other.name == name &&
      other.description == description &&
      other.content == content &&
      other.sourcePath == sourcePath;

  @override
  int get hashCode =>
      Object.hash(name, description, content, sourcePath);
}

/// Session info header stored in JSONL files.
class JsonlSessionMetadata {
  /// Unique session identifier.
  final String id;

  /// Human-readable name.
  final String name;

  /// Creation timestamp (ISO 8601 string).
  final String createdAt;

  /// Last updated timestamp (ISO 8601 string).
  final String updatedAt;

  /// Current leaf entry ID.
  final String? leafId;

  /// Creates JSONL session metadata.
  const JsonlSessionMetadata({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.leafId,
  });

  /// Creates from a JSON map.
  factory JsonlSessionMetadata.fromJson(Map<String, dynamic> json) =>
      JsonlSessionMetadata(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
        updatedAt: json['updatedAt'] as String? ?? '',
        leafId: json['leafId'] as String?,
      );

  /// Converts to a JSON map.
  Map<String, dynamic> toJson() => {
        '_header': true,
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        if (leafId != null) 'leafId': leafId,
      };
}

/// Generates monotonic, collision-free entry IDs.
///
/// ID = fixed-width base36 microsecond timestamp + fixed-width base36
/// per-generator sequence suffix (research R6). The fixed widths make IDs
/// lexicographically sortable, so generation order matches sort order.
///
/// Collision-free under the session's single-writer model: one generator
/// instance per session writer. The global default (used by [newEntryId])
/// backs the common single-session case.
class EntryIdGenerator {
  int _lastMicros = 0;
  int _sequence = 0;

  /// Width of the base36 microsecond timestamp (36^12 spans ~year 60000).
  static const int _timestampWidth = 12;

  /// Width of the base36 sequence suffix (36^3 = 46655 IDs per microsecond).
  static const int _sequenceWidth = 3;

  /// Generates the next ID.
  String next() {
    final now = DateTime.now().microsecondsSinceEpoch;
    if (now > _lastMicros) {
      _lastMicros = now;
      _sequence = 0;
    } else {
      _sequence++;
    }
    final ts = _lastMicros.toRadixString(36).padLeft(_timestampWidth, '0');
    final seq = _sequence.toRadixString(36).padLeft(_sequenceWidth, '0');
    return '$ts$seq';
  }
}

final EntryIdGenerator _globalIdGenerator = EntryIdGenerator();

/// Generates a new session-tree entry ID using the process-wide generator.
String newEntryId() => _globalIdGenerator.next();

bool _blockListEq(List<ContentBlock> a, List<ContentBlock> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _msgListEq(List<AgentMessage> a, List<AgentMessage> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEq(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (a == null || b == null) return identical(a, b);
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}
