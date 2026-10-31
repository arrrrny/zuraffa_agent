// Types and Entities for zuraffa_agent

import 'dart:convert';

import 'domain/entities/artifact_ref/artifact_ref.dart';
import 'domain/entities/branch_summary_entry/branch_summary_entry.dart';
import 'domain/entities/compaction_entry/compaction_entry.dart';
import 'domain/entities/compaction_summary/compaction_summary.dart';
import 'domain/entities/custom_entry/custom_entry.dart';
import 'domain/entities/label_entry/label_entry.dart';
import 'domain/entities/model/model.dart';
import 'domain/entities/model_change_entry/model_change_entry.dart';
import 'domain/entities/thinking_level_change_entry/thinking_level_change_entry.dart';
import 'domain/entities/tool_invocation_record/tool_invocation_record.dart';
import 'domain/entities/turn_record/turn_record.dart';
import 'domain/entities/usage_ledger_entry/usage_ledger_entry.dart';

export 'domain/entities/artifact_ref/artifact_ref.dart';
export 'domain/entities/branch_summary_entry/branch_summary_entry.dart';
export 'domain/entities/compaction_entry/compaction_entry.dart';
export 'domain/entities/compaction_summary/compaction_summary.dart';
export 'domain/entities/custom_entry/custom_entry.dart';
export 'domain/entities/label_entry/label_entry.dart';
export 'domain/entities/model/model.dart';
export 'domain/entities/model_change_entry/model_change_entry.dart';
export 'domain/entities/thinking_level_change_entry/thinking_level_change_entry.dart';
export 'domain/entities/tool_invocation_record/tool_invocation_record.dart';
export 'domain/entities/turn_record/turn_record.dart';
export 'domain/entities/usage_ledger_entry/usage_ledger_entry.dart';

// Monotonic ID Generator (base36 timestamp + sequence counter)
int _entryIdSequence = 0;
int _lastTimestampMicros = 0;

/// Generates a globally unique, monotonically increasing entry identifier.
/// Format: `e_<base36-timestamp-micros>_<sequence>`
String generateEntryId() {
  final nowMicros = DateTime.now().microsecondsSinceEpoch;
  if (nowMicros == _lastTimestampMicros) {
    _entryIdSequence++;
  } else {
    _lastTimestampMicros = nowMicros;
    _entryIdSequence = 0;
  }
  final base36Time = nowMicros.toRadixString(36);
  return 'e_${base36Time}_$_entryIdSequence';
}

// Sealed ContentBlock Hierarchy
/// The content block.
sealed class ContentBlock {
  const ContentBlock();

  /// Converts this content block to JSON.
  Map<String, dynamic> toJson();

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    final type = json['_type'] as String? ?? json['type'] as String;
    switch (type) {
      case 'text':
        return TextBlock.fromJson(json);
      case 'image':
        return ImageBlock.fromJson(json);
      case 'audio':
        return AudioBlock.fromJson(json);
      case 'document':
        return DocumentBlock.fromJson(json);
      case 'toolCall':
      case 'tool_call':
        return ToolCallBlock.fromJson(json);
      case 'thinking':
        return ThinkingBlock.fromJson(json);
      default:
        throw FormatException('Unknown ContentBlock type: $type');
    }
  }
}

/// The text block.
class TextBlock extends ContentBlock {
  /// The text.
  final String text;

  /// Creates a text block.
  const TextBlock(this.text);

  @override
  Map<String, dynamic> toJson() => {'_type': 'text', 'text': text};

  /// Creates a text block from JSON.
  factory TextBlock.fromJson(Map<String, dynamic> json) =>
      TextBlock(json['text'] as String);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextBlock &&
          runtimeType == other.runtimeType &&
          text == other.text;

  @override
  int get hashCode => text.hashCode;
}

/// The image block.
class ImageBlock extends ContentBlock {
  /// The data.
  final String data;

  /// The MIME type.
  final String mimeType;

  /// Creates an image block.
  const ImageBlock({required this.data, required this.mimeType});

  @override
  Map<String, dynamic> toJson() => {
    '_type': 'image',
    'data': data,
    'mimeType': mimeType,
  };

  /// Creates an image block from JSON.
  factory ImageBlock.fromJson(Map<String, dynamic> json) => ImageBlock(
    data: json['data'] as String,
    mimeType: json['mimeType'] as String,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageBlock &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          mimeType == other.mimeType;

  @override
  int get hashCode => Object.hash(data, mimeType);
}

/// The audio block.
class AudioBlock extends ContentBlock {
  /// The data.
  final String data;

  /// The MIME type.
  final String mimeType;

  /// The duration ms.
  final int? durationMs;

  /// Creates an audio block.
  const AudioBlock({
    required this.data,
    required this.mimeType,
    this.durationMs,
  });

  @override
  Map<String, dynamic> toJson() => {
    '_type': 'audio',
    'data': data,
    'mimeType': mimeType,
    if (durationMs != null) 'durationMs': durationMs,
  };

  /// Creates an audio block from JSON.
  factory AudioBlock.fromJson(Map<String, dynamic> json) => AudioBlock(
    data: json['data'] as String,
    mimeType: json['mimeType'] as String,
    durationMs: json['durationMs'] as int?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioBlock &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          mimeType == other.mimeType &&
          durationMs == other.durationMs;

  @override
  int get hashCode => Object.hash(data, mimeType, durationMs);
}

/// The document block.
class DocumentBlock extends ContentBlock {
  /// The data.
  final String data;

  /// The MIME type.
  final String mimeType;

  /// The title.
  final String? title;

  /// Creates a document block.
  const DocumentBlock({required this.data, required this.mimeType, this.title});

  @override
  Map<String, dynamic> toJson() => {
    '_type': 'document',
    'data': data,
    'mimeType': mimeType,
    if (title != null) 'title': title,
  };

  /// Creates a document block from JSON.
  factory DocumentBlock.fromJson(Map<String, dynamic> json) => DocumentBlock(
    data: json['data'] as String,
    mimeType: json['mimeType'] as String,
    title: json['title'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentBlock &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          mimeType == other.mimeType &&
          title == other.title;

  @override
  int get hashCode => Object.hash(data, mimeType, title);
}

/// The tool call block.
class ToolCallBlock extends ContentBlock {
  /// The identifier.
  final String id;

  /// The name.
  final String name;

  /// The arguments.
  final Map<String, dynamic> arguments;

  /// Creates a tool call block.
  const ToolCallBlock({
    required this.id,
    required this.name,
    required this.arguments,
  });

  @override
  Map<String, dynamic> toJson() => {
    '_type': 'toolCall',
    'id': id,
    'name': name,
    'arguments': arguments,
  };

  /// Creates a tool call block from JSON.
  factory ToolCallBlock.fromJson(Map<String, dynamic> json) => ToolCallBlock(
    id: json['id'] as String,
    name: json['name'] as String,
    arguments: Map<String, dynamic>.from(json['arguments'] as Map),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolCallBlock &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          jsonEncode(arguments) == jsonEncode(other.arguments);

  @override
  int get hashCode => Object.hash(id, name);
}

/// The thinking block.
class ThinkingBlock extends ContentBlock {
  /// The thinking.
  final String thinking;

  /// The signature.
  final String? signature;

  /// Creates a thinking block.
  const ThinkingBlock({required this.thinking, this.signature});

  @override
  Map<String, dynamic> toJson() => {
    '_type': 'thinking',
    'thinking': thinking,
    if (signature != null) 'signature': signature,
  };

  /// Creates a thinking block from JSON.
  factory ThinkingBlock.fromJson(Map<String, dynamic> json) => ThinkingBlock(
    thinking: json['thinking'] as String,
    signature: json['signature'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThinkingBlock &&
          runtimeType == other.runtimeType &&
          thinking == other.thinking &&
          signature == other.signature;

  @override
  int get hashCode => Object.hash(thinking, signature);
}

// Sealed AgentMessage Hierarchy
/// The agent message.
sealed class AgentMessage {
  /// The timestamp.
  final DateTime timestamp;

  const AgentMessage({DateTime? timestamp})
    : timestamp = timestamp ?? const _DefaultDateTime();

  /// Converts this agent message to JSON.
  Map<String, dynamic> toJson();

  factory AgentMessage.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String;
    switch (role) {
      case 'user':
        return UserMessage.fromJson(json);
      case 'assistant':
        return AssistantMessage.fromJson(json);
      case 'toolResult':
      case 'tool_result':
        return ToolResultMessage.fromJson(json);
      case 'custom':
        return CustomMessage.fromJson(json);
      default:
        throw FormatException('Unknown AgentMessage role: $role');
    }
  }
}

/// Sentinel type for default/unset timestamps. Checked via
/// `is _DefaultDateTime`; never accessed as a real DateTime.
class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// The user message.
class UserMessage extends AgentMessage {
  /// The content.
  final List<ContentBlock> content;

  /// Creates an user message.
  UserMessage({required this.content, super.timestamp});

  /// Creates an user message (text variant).
  factory UserMessage.text(String text) =>
      UserMessage(content: [TextBlock(text)]);

  @override
  Map<String, dynamic> toJson() => {
    'role': 'user',
    'content': content.map((c) => c.toJson()).toList(),
    'timestamp':
        (timestamp is _DefaultDateTime ? DateTime.now().toUtc() : timestamp)
            .toIso8601String(),
  };

  /// Creates an user message from JSON.
  factory UserMessage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    final List<ContentBlock> blocks;
    if (rawContent is String) {
      blocks = [TextBlock(rawContent)];
    } else if (rawContent is List) {
      blocks = rawContent
          .map(
            (item) => item is String
                ? TextBlock(item)
                : ContentBlock.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } else {
      blocks = [];
    }
    return UserMessage(
      content: blocks,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }
}

/// The assistant message.
class AssistantMessage extends AgentMessage {
  /// The content.
  final List<ContentBlock> content;

  /// Creates an assistant message.
  AssistantMessage({required this.content, super.timestamp});

  /// Creates an assistant message (text variant).
  factory AssistantMessage.text(String text) =>
      AssistantMessage(content: [TextBlock(text)]);

  @override
  Map<String, dynamic> toJson() => {
    'role': 'assistant',
    'content': content.map((c) => c.toJson()).toList(),
    'timestamp':
        (timestamp is _DefaultDateTime ? DateTime.now().toUtc() : timestamp)
            .toIso8601String(),
  };

  /// Creates an assistant message from JSON.
  factory AssistantMessage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    final List<ContentBlock> blocks;
    if (rawContent is String) {
      blocks = [TextBlock(rawContent)];
    } else if (rawContent is List) {
      blocks = rawContent
          .map(
            (item) => item is String
                ? TextBlock(item)
                : ContentBlock.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } else {
      blocks = [];
    }
    return AssistantMessage(
      content: blocks,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }
}

/// The tool result message.
class ToolResultMessage extends AgentMessage {
  /// The tool call identifier.
  final String toolCallId;

  /// The tool name.
  final String toolName;

  /// The content.
  final String content;

  /// Whether error.
  final bool isError;

  /// The artifact refs.
  final List<ArtifactRef> artifactRefs;

  /// Creates a tool result message.
  ToolResultMessage({
    required this.toolCallId,
    required this.toolName,
    required this.content,
    this.isError = false,
    this.artifactRefs = const [],
    super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() => {
    'role': 'toolResult',
    'toolCallId': toolCallId,
    'toolName': toolName,
    'content': content,
    'isError': isError,
    'artifactRefs': artifactRefs.map((a) => a.toJson()).toList(),
    'timestamp':
        (timestamp is _DefaultDateTime ? DateTime.now().toUtc() : timestamp)
            .toIso8601String(),
  };

  /// Creates a tool result message from JSON.
  factory ToolResultMessage.fromJson(Map<String, dynamic> json) =>
      ToolResultMessage(
        toolCallId: json['toolCallId'] as String,
        toolName: json['toolName'] as String,
        content: json['content'] as String,
        isError: json['isError'] as bool? ?? false,
        artifactRefs:
            (json['artifactRefs'] as List?)
                ?.map(
                  (item) => ArtifactRef.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList() ??
            const [],
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : null,
      );
}

/// The custom message.
class CustomMessage extends AgentMessage {
  /// The message type.
  final String messageType;

  /// The payload.
  final Map<String, dynamic> payload;

  /// Creates a custom message.
  CustomMessage({
    required this.messageType,
    required this.payload,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() => {
    'role': 'custom',
    'messageType': messageType,
    'payload': payload,
    'timestamp':
        (timestamp is _DefaultDateTime ? DateTime.now().toUtc() : timestamp)
            .toIso8601String(),
  };

  /// Creates a custom message from JSON.
  factory CustomMessage.fromJson(Map<String, dynamic> json) => CustomMessage(
    messageType: json['messageType'] as String,
    payload: Map<String, dynamic>.from(json['payload'] as Map),
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'] as String)
        : null,
  );
}

// Sealed SessionTreeEntry Hierarchy
/// The session tree entry.
sealed class SessionTreeEntry {
  /// The identifier.
  final String id;

  /// The parent identifier.
  final String? parentId;

  /// The timestamp.
  final DateTime timestamp;

  const SessionTreeEntry({
    required this.id,
    this.parentId,
    required this.timestamp,
  });

  /// Converts this session tree entry to JSON.
  Map<String, dynamic> toJson();

  factory SessionTreeEntry.fromJson(Map<String, dynamic> json) {
    final type = json['_type'] as String? ?? json['type'] as String;
    switch (type) {
      case 'message':
        return MessageEntry.fromJson(json);
      case 'turn':
      case 'turnRecord':
        return TurnRecordEntry.fromJson(json);
      case 'toolInvocation':
      case 'tool_invocation':
        return ToolInvocationEntry.fromJson(json);
      case 'usage':
      case 'usageLedger':
        return UsageEntry.fromJson(json);
      case 'compaction':
        return CompactionTreeEntry.fromJson(json);
      case 'thinkingLevel':
      case 'thinking_level':
        return ThinkingLevelEntry.fromJson(json);
      case 'modelChange':
      case 'model_change':
        return ModelChangeTreeEntry.fromJson(json);
      case 'branchSummary':
      case 'branch_summary':
        return BranchSummaryTreeEntry.fromJson(json);
      case 'label':
        return LabelTreeEntry.fromJson(json);
      case 'custom':
        return CustomTreeEntry.fromJson(json);
      default:
        throw FormatException('Unknown SessionTreeEntry type: $type');
    }
  }
}

/// The message entry.
class MessageEntry extends SessionTreeEntry {
  /// The message.
  final AgentMessage message;

  /// Creates a message entry.
  const MessageEntry({
    required super.id,
    super.parentId,
    required super.timestamp,
    required this.message,
  });

  @override
  Map<String, dynamic> toJson() => {
    '_type': 'message',
    'id': id,
    'parentId': parentId,
    'timestamp': timestamp.toIso8601String(),
    'message': message.toJson(),
  };

  /// Creates a message entry from JSON.
  factory MessageEntry.fromJson(Map<String, dynamic> json) => MessageEntry(
    id: json['id'] as String,
    parentId: json['parentId'] as String?,
    timestamp: DateTime.parse(json['timestamp'] as String),
    message: AgentMessage.fromJson(
      Map<String, dynamic>.from(json['message'] as Map),
    ),
  );
}

/// The turn record entry.
class TurnRecordEntry extends SessionTreeEntry {
  /// The record.
  final TurnRecord record;

  /// Creates a turn record entry.
  const TurnRecordEntry({
    required super.id,
    super.parentId,
    required super.timestamp,
    required this.record,
  });

  @override
  Map<String, dynamic> toJson() => {
    '_type': 'turn',
    'id': id,
    'parentId': parentId,
    'timestamp': timestamp.toIso8601String(),
    'record': record.toJson(),
  };

  /// Creates a turn record entry from JSON.
  factory TurnRecordEntry.fromJson(Map<String, dynamic> json) =>
      TurnRecordEntry(
        id: json['id'] as String,
        parentId: json['parentId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        record: TurnRecord.fromJson(
          Map<String, dynamic>.from(json['record'] as Map),
        ),
      );
}

/// The tool invocation entry.
class ToolInvocationEntry extends SessionTreeEntry {
  /// The record.
  final ToolInvocationRecord record;

  /// The arguments.
  final Map<String, dynamic> arguments;

  /// The artifact refs.
  final List<ArtifactRef> artifactRefs;

  /// Creates a tool invocation entry.
  const ToolInvocationEntry({
    required super.id,
    super.parentId,
    required super.timestamp,
    required this.record,
    this.arguments = const {},
    this.artifactRefs = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
    '_type': 'toolInvocation',
    'id': id,
    'parentId': parentId,
    'timestamp': timestamp.toIso8601String(),
    'record': record.toJson(),
    'arguments': arguments,
    'artifactRefs': artifactRefs.map((a) => a.toJson()).toList(),
  };

  /// Creates a tool invocation entry from JSON.
  factory ToolInvocationEntry.fromJson(Map<String, dynamic> json) =>
      ToolInvocationEntry(
        id: json['id'] as String,
        parentId: json['parentId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        record: ToolInvocationRecord.fromJson(
          Map<String, dynamic>.from(json['record'] as Map),
        ),
        arguments: json['arguments'] != null
            ? Map<String, dynamic>.from(json['arguments'] as Map)
            : const {},
        artifactRefs:
            (json['artifactRefs'] as List?)
                ?.map(
                  (item) => ArtifactRef.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList() ??
            const [],
      );
}

/// The usage entry.
class UsageEntry extends SessionTreeEntry {
  /// The record.
  final UsageLedgerEntry record;

  /// The model.
  final Model? model;

  /// Creates an usage entry.
  const UsageEntry({
    required super.id,
    super.parentId,
    required super.timestamp,
    required this.record,
    this.model,
  });

  @override
  Map<String, dynamic> toJson() => {
    '_type': 'usage',
    'id': id,
    'parentId': parentId,
    'timestamp': timestamp.toIso8601String(),
    'record': record.toJson(),
    if (model != null) 'model': model!.toJson(),
  };

  /// Creates an usage entry from JSON.
  factory UsageEntry.fromJson(Map<String, dynamic> json) => UsageEntry(
    id: json['id'] as String,
    parentId: json['parentId'] as String?,
    timestamp: DateTime.parse(json['timestamp'] as String),
    record: UsageLedgerEntry.fromJson(
      Map<String, dynamic>.from(json['record'] as Map),
    ),
    model: json['model'] != null
        ? Model.fromJson(Map<String, dynamic>.from(json['model'] as Map))
        : null,
  );
}

/// The compaction tree entry.
class CompactionTreeEntry extends SessionTreeEntry {
  /// The record.
  final CompactionEntry record;

  /// The summary.
  final CompactionSummary summary;

  /// Creates a compaction tree entry.
  const CompactionTreeEntry({
    required super.id,
    super.parentId,
    required super.timestamp,
    required this.record,
    required this.summary,
  });

  @override
  Map<String, dynamic> toJson() => {
    '_type': 'compaction',
    'id': id,
    'parentId': parentId,
    'timestamp': timestamp.toIso8601String(),
    'record': record.toJson(),
    'summary': summary.toJson(),
  };

  /// Creates a compaction tree entry from JSON.
  factory CompactionTreeEntry.fromJson(Map<String, dynamic> json) =>
      CompactionTreeEntry(
        id: json['id'] as String,
        parentId: json['parentId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        record: CompactionEntry.fromJson(
          Map<String, dynamic>.from(json['record'] as Map),
        ),
        summary: CompactionSummary.fromJson(
          Map<String, dynamic>.from(json['summary'] as Map),
        ),
      );
}

/// The thinking level entry.
class ThinkingLevelEntry extends SessionTreeEntry {
  /// The record.
  final ThinkingLevelChangeEntry record;

  /// Creates a thinking level entry.
  const ThinkingLevelEntry({
    required super.id,
    super.parentId,
    required super.timestamp,
    required this.record,
  });

  @override
  Map<String, dynamic> toJson() => {
    '_type': 'thinkingLevel',
    'id': id,
    'parentId': parentId,
    'timestamp': timestamp.toIso8601String(),
    'record': record.toJson(),
  };

  /// Creates a thinking level entry from JSON.
  factory ThinkingLevelEntry.fromJson(Map<String, dynamic> json) =>
      ThinkingLevelEntry(
        id: json['id'] as String,
        parentId: json['parentId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        record: ThinkingLevelChangeEntry.fromJson(
          Map<String, dynamic>.from(json['record'] as Map),
        ),
      );
}

/// The model change tree entry.
class ModelChangeTreeEntry extends SessionTreeEntry {
  /// The record.
  final ModelChangeEntry record;

  /// Creates a model change tree entry.
  const ModelChangeTreeEntry({
    required super.id,
    super.parentId,
    required super.timestamp,
    required this.record,
  });

  @override
  Map<String, dynamic> toJson() => {
    '_type': 'modelChange',
    'id': id,
    'parentId': parentId,
    'timestamp': timestamp.toIso8601String(),
    'record': record.toJson(),
  };

  /// Creates a model change tree entry from JSON.
  factory ModelChangeTreeEntry.fromJson(Map<String, dynamic> json) =>
      ModelChangeTreeEntry(
        id: json['id'] as String,
        parentId: json['parentId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        record: ModelChangeEntry.fromJson(
          Map<String, dynamic>.from(json['record'] as Map),
        ),
      );
}

/// The branch summary tree entry.
class BranchSummaryTreeEntry extends SessionTreeEntry {
  /// The record.
  final BranchSummaryEntry record;

  /// Creates a branch summary tree entry.
  const BranchSummaryTreeEntry({
    required super.id,
    super.parentId,
    required super.timestamp,
    required this.record,
  });

  @override
  Map<String, dynamic> toJson() => {
    '_type': 'branchSummary',
    'id': id,
    'parentId': parentId,
    'timestamp': timestamp.toIso8601String(),
    'record': record.toJson(),
  };

  /// Creates a branch summary tree entry from JSON.
  factory BranchSummaryTreeEntry.fromJson(Map<String, dynamic> json) =>
      BranchSummaryTreeEntry(
        id: json['id'] as String,
        parentId: json['parentId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        record: BranchSummaryEntry.fromJson(
          Map<String, dynamic>.from(json['record'] as Map),
        ),
      );
}

/// The label tree entry.
class LabelTreeEntry extends SessionTreeEntry {
  /// The record.
  final LabelEntry record;

  /// Creates a label tree entry.
  const LabelTreeEntry({
    required super.id,
    super.parentId,
    required super.timestamp,
    required this.record,
  });

  @override
  Map<String, dynamic> toJson() => {
    '_type': 'label',
    'id': id,
    'parentId': parentId,
    'timestamp': timestamp.toIso8601String(),
    'record': record.toJson(),
  };

  /// Creates a label tree entry from JSON.
  factory LabelTreeEntry.fromJson(Map<String, dynamic> json) => LabelTreeEntry(
    id: json['id'] as String,
    parentId: json['parentId'] as String?,
    timestamp: DateTime.parse(json['timestamp'] as String),
    record: LabelEntry.fromJson(
      Map<String, dynamic>.from(json['record'] as Map),
    ),
  );
}

/// The custom tree entry.
class CustomTreeEntry extends SessionTreeEntry {
  /// The record.
  final CustomEntry record;

  /// Creates a custom tree entry.
  const CustomTreeEntry({
    required super.id,
    super.parentId,
    required super.timestamp,
    required this.record,
  });

  @override
  Map<String, dynamic> toJson() => {
    '_type': 'custom',
    'id': id,
    'parentId': parentId,
    'timestamp': timestamp.toIso8601String(),
    'record': record.toJson(),
  };

  /// Creates a custom tree entry from JSON.
  factory CustomTreeEntry.fromJson(Map<String, dynamic> json) =>
      CustomTreeEntry(
        id: json['id'] as String,
        parentId: json['parentId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        record: CustomEntry.fromJson(
          Map<String, dynamic>.from(json['record'] as Map),
        ),
      );
}
