// NEW file for zuraffa_agent (no pi_agent equivalent): hand-written Hive
// TypeAdapters for the sealed entity/message hierarchies (research R4).
// Source licensed MIT under zuraffa_agent. See NOTICE.
//
// The `hive_ce` import lives only here and in `hive_session_store.dart`
// (plan.md quarantine). Explicit deterministic type IDs keep Hive files
// stable across releases and make cross-store equivalence tests possible.
library;

import 'package:hive_ce/hive_ce.dart'
    show BinaryReader, BinaryWriter, Hive, TypeAdapter;

import 'compaction.dart';
import 'types.dart';

/// Deterministic Hive type IDs (research R4).
///
/// These are part of the on-disk contract: changing an ID breaks existing
/// Hive files, so every ID is pinned by test (test/hive_store_test.dart).
abstract final class HiveTypeIds {
  // Messages
  static const int userMessage = 10;
  static const int assistantMessage = 11;
  static const int toolResultMessage = 12;
  static const int customMessage = 13;

  // Content blocks
  static const int textBlock = 20;
  static const int imageBlock = 21;
  static const int audioBlock = 22;
  static const int documentBlock = 23;
  static const int toolCallBlock = 24;
  static const int thinkingBlock = 25;

  // Session-tree entries
  static const int messageEntry = 30;
  static const int thinkingLevelChangeEntry = 31;
  static const int modelChangeEntry = 32;
  static const int compactionEntry = 33;
  static const int branchSummaryEntry = 34;
  static const int labelEntry = 35;
  static const int customEntry = 36;
  static const int turnRecord = 37;
  static const int toolInvocationRecord = 38;
  static const int usageLedgerEntry = 39;

  // Support value objects
  static const int model = 40;
  static const int usage = 41;
  static const int compactionSummary = 42;
  static const int artifactRef = 43;
  static const int sessionInfo = 44;
}

/// Registers every zuraffa adapter with Hive.
///
/// Idempotent: adapters already registered (e.g. by an earlier store open in
/// the same process) are left in place, so no override warnings are emitted.
/// Each adapter is registered with its concrete generic type so Hive
/// dispatches by runtime type (registering a `<Object>` adapter would steal
/// every write).
void registerZuraffaAdapters() {
  void register<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  register<UserMessage>(UserMessageAdapter());
  register<AssistantMessage>(AssistantMessageAdapter());
  register<ToolResultMessage>(ToolResultMessageAdapter());
  register<CustomMessage>(CustomMessageAdapter());
  register<TextBlock>(TextBlockAdapter());
  register<ImageBlock>(ImageBlockAdapter());
  register<AudioBlock>(AudioBlockAdapter());
  register<DocumentBlock>(DocumentBlockAdapter());
  register<ToolCallBlock>(ToolCallBlockAdapter());
  register<ThinkingBlock>(ThinkingBlockAdapter());
  register<MessageEntry>(MessageEntryAdapter());
  register<ThinkingLevelChangeEntry>(ThinkingLevelChangeEntryAdapter());
  register<ModelChangeEntry>(ModelChangeEntryAdapter());
  register<CompactionEntry>(CompactionEntryAdapter());
  register<BranchSummaryEntry>(BranchSummaryEntryAdapter());
  register<LabelEntry>(LabelEntryAdapter());
  register<CustomEntry>(CustomEntryAdapter());
  register<TurnRecord>(TurnRecordAdapter());
  register<ToolInvocationRecord>(ToolInvocationRecordAdapter());
  register<UsageLedgerEntry>(UsageLedgerEntryAdapter());
  register<Model>(ModelAdapter());
  register<Usage>(UsageAdapter());
  register<CompactionSummary>(CompactionSummaryAdapter());
  register<ArtifactRef>(ArtifactRefAdapter());
  register<SessionInfo>(SessionInfoAdapter());
}

// ---------------------------------------------------------------------------
// Shared write/read helpers for base entry fields and nullable members.
// ---------------------------------------------------------------------------

void _writeBase(BinaryWriter w, SessionTreeEntry e) {
  w.writeString(e.id);
  w.writeString(e.parentId);
  w.writeString(e.timestamp.toIso8601String());
}

(String, String, DateTime) _readBase(BinaryReader r) => (
      r.readString(),
      r.readString(),
      DateTime.parse(r.readString()),
    );

void _writeNullableString(BinaryWriter w, String? s) {
  w.writeBool(s != null);
  if (s != null) w.writeString(s);
}

String? _readNullableString(BinaryReader r) =>
    r.readBool() ? r.readString() : null;

void _writeNullableInt(BinaryWriter w, int? v) {
  w.writeBool(v != null);
  if (v != null) w.writeInt(v);
}

int? _readNullableInt(BinaryReader r) => r.readBool() ? r.readInt() : null;

void _writeNullableEnum(BinaryWriter w, Enum? e) {
  w.writeBool(e != null);
  if (e != null) w.writeByte(e.index);
}

T? _readNullableEnum<T extends Enum>(BinaryReader r, List<T> values) =>
    r.readBool() ? values[r.readByte()] : null;

void _writeContentBlocks(BinaryWriter w, List<ContentBlock> blocks) =>
    w.writeList(blocks);

List<ContentBlock> _readContentBlocks(BinaryReader r) =>
    r.readList().whereType<ContentBlock>().toList();

Map<String, dynamic> _readStringMap(BinaryReader r) =>
    Map<String, dynamic>.from(r.readMap());

// ---------------------------------------------------------------------------
// Message adapters
// ---------------------------------------------------------------------------

/// Adapter for [UserMessage].
class UserMessageAdapter extends TypeAdapter<UserMessage> {
  @override
  final int typeId = HiveTypeIds.userMessage;

  @override
  UserMessage read(BinaryReader reader) =>
      UserMessage(content: _readContentBlocks(reader));

  @override
  void write(BinaryWriter writer, UserMessage obj) =>
      _writeContentBlocks(writer, obj.content);
}

/// Adapter for [AssistantMessage].
class AssistantMessageAdapter extends TypeAdapter<AssistantMessage> {
  @override
  final int typeId = HiveTypeIds.assistantMessage;

  @override
  AssistantMessage read(BinaryReader reader) => AssistantMessage(
        id: _readNullableString(reader),
        content: _readContentBlocks(reader),
        stopReason: _readNullableEnum(reader, StopReason.values),
        usage: reader.readBool() ? reader.read() as Usage : null,
      );

  @override
  void write(BinaryWriter writer, AssistantMessage obj) {
    _writeNullableString(writer, obj.id);
    _writeContentBlocks(writer, obj.content);
    _writeNullableEnum(writer, obj.stopReason);
    final usage = obj.usage;
    writer.writeBool(usage != null);
    if (usage != null) {
      writer.write(usage);
    }
  }
}

/// Adapter for [ToolResultMessage].
class ToolResultMessageAdapter extends TypeAdapter<ToolResultMessage> {
  @override
  final int typeId = HiveTypeIds.toolResultMessage;

  @override
  ToolResultMessage read(BinaryReader reader) => ToolResultMessage(
        toolCallId: reader.readString(),
        toolName: reader.readString(),
        content: _readContentBlocks(reader),
        isError: reader.readBool(),
      );

  @override
  void write(BinaryWriter writer, ToolResultMessage obj) {
    writer.writeString(obj.toolCallId);
    writer.writeString(obj.toolName);
    _writeContentBlocks(writer, obj.content);
    writer.writeBool(obj.isError);
  }
}

/// Adapter for [CustomMessage].
class CustomMessageAdapter extends TypeAdapter<CustomMessage> {
  @override
  final int typeId = HiveTypeIds.customMessage;

  @override
  CustomMessage read(BinaryReader reader) => CustomMessage(
        type: reader.readString(),
        data: _readStringMap(reader),
        display: reader.readString(),
      );

  @override
  void write(BinaryWriter writer, CustomMessage obj) {
    writer.writeString(obj.type);
    writer.writeMap(obj.data);
    writer.writeString(obj.display);
  }
}

// ---------------------------------------------------------------------------
// Content block adapters
// ---------------------------------------------------------------------------

/// Adapter for [TextBlock].
class TextBlockAdapter extends TypeAdapter<TextBlock> {
  @override
  final int typeId = HiveTypeIds.textBlock;

  @override
  TextBlock read(BinaryReader reader) => TextBlock(reader.readString());

  @override
  void write(BinaryWriter writer, TextBlock obj) =>
      writer.writeString(obj.text);
}

/// Adapter for [ImageBlock].
class ImageBlockAdapter extends TypeAdapter<ImageBlock> {
  @override
  final int typeId = HiveTypeIds.imageBlock;

  @override
  ImageBlock read(BinaryReader reader) => ImageBlock(
        base64Data: reader.readString(),
        mediaType: reader.readString(),
      );

  @override
  void write(BinaryWriter writer, ImageBlock obj) {
    writer.writeString(obj.base64Data);
    writer.writeString(obj.mediaType);
  }
}

/// Adapter for [AudioBlock].
class AudioBlockAdapter extends TypeAdapter<AudioBlock> {
  @override
  final int typeId = HiveTypeIds.audioBlock;

  @override
  AudioBlock read(BinaryReader reader) => AudioBlock(
        base64Data: reader.readString(),
        mediaType: reader.readString(),
        transcript: _readNullableString(reader),
      );

  @override
  void write(BinaryWriter writer, AudioBlock obj) {
    writer.writeString(obj.base64Data);
    writer.writeString(obj.mediaType);
    _writeNullableString(writer, obj.transcript);
  }
}

/// Adapter for [DocumentBlock].
class DocumentBlockAdapter extends TypeAdapter<DocumentBlock> {
  @override
  final int typeId = HiveTypeIds.documentBlock;

  @override
  DocumentBlock read(BinaryReader reader) => DocumentBlock(
        mediaType: reader.readString(),
        base64Data: reader.readString(),
        title: _readNullableString(reader),
      );

  @override
  void write(BinaryWriter writer, DocumentBlock obj) {
    writer.writeString(obj.mediaType);
    writer.writeString(obj.base64Data);
    _writeNullableString(writer, obj.title);
  }
}

/// Adapter for [ToolCallBlock].
class ToolCallBlockAdapter extends TypeAdapter<ToolCallBlock> {
  @override
  final int typeId = HiveTypeIds.toolCallBlock;

  @override
  ToolCallBlock read(BinaryReader reader) => ToolCallBlock(
        id: reader.readString(),
        name: reader.readString(),
        arguments: _readStringMap(reader),
      );

  @override
  void write(BinaryWriter writer, ToolCallBlock obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeMap(obj.arguments);
  }
}

/// Adapter for [ThinkingBlock].
class ThinkingBlockAdapter extends TypeAdapter<ThinkingBlock> {
  @override
  final int typeId = HiveTypeIds.thinkingBlock;

  @override
  ThinkingBlock read(BinaryReader reader) =>
      ThinkingBlock(reader.readString());

  @override
  void write(BinaryWriter writer, ThinkingBlock obj) =>
      writer.writeString(obj.text);
}

// ---------------------------------------------------------------------------
// Session-tree entry adapters
// ---------------------------------------------------------------------------

/// Adapter for [MessageEntry].
class MessageEntryAdapter extends TypeAdapter<MessageEntry> {
  @override
  final int typeId = HiveTypeIds.messageEntry;

  @override
  MessageEntry read(BinaryReader reader) {
    final (id, parentId, timestamp) = _readBase(reader);
    return MessageEntry(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      role: reader.readString(),
      message: reader.read() as AgentMessage,
    );
  }

  @override
  void write(BinaryWriter writer, MessageEntry obj) {
    _writeBase(writer, obj);
    writer.writeString(obj.role);
    writer.write(obj.message);
  }
}

/// Adapter for [ThinkingLevelChangeEntry].
class ThinkingLevelChangeEntryAdapter
    extends TypeAdapter<ThinkingLevelChangeEntry> {
  @override
  final int typeId = HiveTypeIds.thinkingLevelChangeEntry;

  @override
  ThinkingLevelChangeEntry read(BinaryReader reader) {
    final (id, parentId, timestamp) = _readBase(reader);
    return ThinkingLevelChangeEntry(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      level: ThinkingLevel.values[reader.readByte()],
    );
  }

  @override
  void write(BinaryWriter writer, ThinkingLevelChangeEntry obj) {
    _writeBase(writer, obj);
    writer.writeByte(obj.level.index);
  }
}

/// Adapter for [ModelChangeEntry].
class ModelChangeEntryAdapter extends TypeAdapter<ModelChangeEntry> {
  @override
  final int typeId = HiveTypeIds.modelChangeEntry;

  @override
  ModelChangeEntry read(BinaryReader reader) {
    final (id, parentId, timestamp) = _readBase(reader);
    return ModelChangeEntry(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      provider: reader.readString(),
      modelId: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, ModelChangeEntry obj) {
    _writeBase(writer, obj);
    writer.writeString(obj.provider);
    writer.writeString(obj.modelId);
  }
}

/// Adapter for [CompactionEntry].
class CompactionEntryAdapter extends TypeAdapter<CompactionEntry> {
  @override
  final int typeId = HiveTypeIds.compactionEntry;

  @override
  CompactionEntry read(BinaryReader reader) {
    final (id, parentId, timestamp) = _readBase(reader);
    return CompactionEntry(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      summary: reader.read() as CompactionSummary,
      firstKeptEntryId: reader.readString(),
      tokensBefore: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, CompactionEntry obj) {
    _writeBase(writer, obj);
    writer.write(obj.summary);
    writer.writeString(obj.firstKeptEntryId);
    writer.writeInt(obj.tokensBefore);
  }
}

/// Adapter for [BranchSummaryEntry].
class BranchSummaryEntryAdapter extends TypeAdapter<BranchSummaryEntry> {
  @override
  final int typeId = HiveTypeIds.branchSummaryEntry;

  @override
  BranchSummaryEntry read(BinaryReader reader) {
    final (id, parentId, timestamp) = _readBase(reader);
    return BranchSummaryEntry(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      summary: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, BranchSummaryEntry obj) {
    _writeBase(writer, obj);
    writer.writeString(obj.summary);
  }
}

/// Adapter for [LabelEntry].
class LabelEntryAdapter extends TypeAdapter<LabelEntry> {
  @override
  final int typeId = HiveTypeIds.labelEntry;

  @override
  LabelEntry read(BinaryReader reader) {
    final (id, parentId, timestamp) = _readBase(reader);
    return LabelEntry(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      targetId: reader.readString(),
      label: _readNullableString(reader),
    );
  }

  @override
  void write(BinaryWriter writer, LabelEntry obj) {
    _writeBase(writer, obj);
    writer.writeString(obj.targetId);
    _writeNullableString(writer, obj.label);
  }
}

/// Adapter for [CustomEntry].
class CustomEntryAdapter extends TypeAdapter<CustomEntry> {
  @override
  final int typeId = HiveTypeIds.customEntry;

  @override
  CustomEntry read(BinaryReader reader) {
    final (id, parentId, timestamp) = _readBase(reader);
    return CustomEntry(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      customType: reader.readString(),
      data: reader.readBool() ? _readStringMap(reader) : null,
    );
  }

  @override
  void write(BinaryWriter writer, CustomEntry obj) {
    _writeBase(writer, obj);
    writer.writeString(obj.customType);
    final data = obj.data;
    writer.writeBool(data != null);
    if (data != null) {
      writer.writeMap(data);
    }
  }
}

/// Adapter for [TurnRecord].
class TurnRecordAdapter extends TypeAdapter<TurnRecord> {
  @override
  final int typeId = HiveTypeIds.turnRecord;

  @override
  TurnRecord read(BinaryReader reader) {
    final (id, parentId, timestamp) = _readBase(reader);
    return TurnRecord(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      turnNumber: reader.readInt(),
      messageEntryIds: reader.readStringList(),
      stopReason: _readNullableEnum(reader, StopReason.values),
      startedAt: DateTime.parse(reader.readString()),
      endedAt: DateTime.parse(reader.readString()),
      durationMs: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, TurnRecord obj) {
    _writeBase(writer, obj);
    writer.writeInt(obj.turnNumber);
    writer.writeStringList(obj.messageEntryIds);
    _writeNullableEnum(writer, obj.stopReason);
    writer.writeString(obj.startedAt.toIso8601String());
    writer.writeString(obj.endedAt.toIso8601String());
    writer.writeInt(obj.durationMs);
  }
}

/// Adapter for [ToolInvocationRecord].
class ToolInvocationRecordAdapter extends TypeAdapter<ToolInvocationRecord> {
  @override
  final int typeId = HiveTypeIds.toolInvocationRecord;

  @override
  ToolInvocationRecord read(BinaryReader reader) {
    final (id, parentId, timestamp) = _readBase(reader);
    return ToolInvocationRecord(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      toolCallId: reader.readString(),
      toolName: reader.readString(),
      arguments: _readStringMap(reader),
      resultEntryId: _readNullableString(reader),
      isError: reader.readBool(),
      durationMs: reader.readInt(),
      artifactRefs: reader.readList().whereType<ArtifactRef>().toList(),
    );
  }

  @override
  void write(BinaryWriter writer, ToolInvocationRecord obj) {
    _writeBase(writer, obj);
    writer.writeString(obj.toolCallId);
    writer.writeString(obj.toolName);
    writer.writeMap(obj.arguments);
    _writeNullableString(writer, obj.resultEntryId);
    writer.writeBool(obj.isError);
    writer.writeInt(obj.durationMs);
    writer.writeList(obj.artifactRefs);
  }
}

/// Adapter for [UsageLedgerEntry].
class UsageLedgerEntryAdapter extends TypeAdapter<UsageLedgerEntry> {
  @override
  final int typeId = HiveTypeIds.usageLedgerEntry;

  @override
  UsageLedgerEntry read(BinaryReader reader) {
    final (id, parentId, timestamp) = _readBase(reader);
    return UsageLedgerEntry(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      callId: reader.readString(),
      turnNumber: reader.readInt(),
      model: reader.read() as Model,
      inputTokens: reader.readInt(),
      outputTokens: reader.readInt(),
      cacheCreationInputTokens: _readNullableInt(reader),
      cacheReadInputTokens: _readNullableInt(reader),
    );
  }

  @override
  void write(BinaryWriter writer, UsageLedgerEntry obj) {
    _writeBase(writer, obj);
    writer.writeString(obj.callId);
    writer.writeInt(obj.turnNumber);
    writer.write(obj.model);
    writer.writeInt(obj.inputTokens);
    writer.writeInt(obj.outputTokens);
    _writeNullableInt(writer, obj.cacheCreationInputTokens);
    _writeNullableInt(writer, obj.cacheReadInputTokens);
  }
}

// ---------------------------------------------------------------------------
// Support value object adapters
// ---------------------------------------------------------------------------

/// Adapter for [Model].
class ModelAdapter extends TypeAdapter<Model> {
  @override
  final int typeId = HiveTypeIds.model;

  @override
  Model read(BinaryReader reader) => Model(
        provider: reader.readString(),
        modelId: reader.readString(),
        contextWindow: reader.readInt(),
        supportsVision: reader.readBool(),
        supportsThinking: reader.readBool(),
        supportsTools: reader.readBool(),
        extra: reader.readBool() ? _readStringMap(reader) : null,
      );

  @override
  void write(BinaryWriter writer, Model obj) {
    writer.writeString(obj.provider);
    writer.writeString(obj.modelId);
    writer.writeInt(obj.contextWindow);
    writer.writeBool(obj.supportsVision);
    writer.writeBool(obj.supportsThinking);
    writer.writeBool(obj.supportsTools);
    final extra = obj.extra;
    writer.writeBool(extra != null);
    if (extra != null) {
      writer.writeMap(extra);
    }
  }
}

/// Adapter for [Usage].
class UsageAdapter extends TypeAdapter<Usage> {
  @override
  final int typeId = HiveTypeIds.usage;

  @override
  Usage read(BinaryReader reader) => Usage(
        inputTokens: reader.readInt(),
        outputTokens: reader.readInt(),
        cacheCreationInputTokens: _readNullableInt(reader),
        cacheReadInputTokens: _readNullableInt(reader),
      );

  @override
  void write(BinaryWriter writer, Usage obj) {
    writer.writeInt(obj.inputTokens);
    writer.writeInt(obj.outputTokens);
    _writeNullableInt(writer, obj.cacheCreationInputTokens);
    _writeNullableInt(writer, obj.cacheReadInputTokens);
  }
}

/// Adapter for [CompactionSummary].
class CompactionSummaryAdapter extends TypeAdapter<CompactionSummary> {
  @override
  final int typeId = HiveTypeIds.compactionSummary;

  @override
  CompactionSummary read(BinaryReader reader) => CompactionSummary(
        decisions: reader.readStringList(),
        toolNames: reader.readStringList(),
        keyResults: reader.readStringList(),
        planState: _readNullableString(reader),
        artifacts: reader.readList().whereType<ArtifactRef>().toList(),
        prose: _readNullableString(reader),
      );

  @override
  void write(BinaryWriter writer, CompactionSummary obj) {
    writer.writeStringList(obj.decisions);
    writer.writeStringList(obj.toolNames);
    writer.writeStringList(obj.keyResults);
    _writeNullableString(writer, obj.planState);
    writer.writeList(obj.artifacts);
    _writeNullableString(writer, obj.prose);
  }
}

/// Adapter for [ArtifactRef].
class ArtifactRefAdapter extends TypeAdapter<ArtifactRef> {
  @override
  final int typeId = HiveTypeIds.artifactRef;

  @override
  ArtifactRef read(BinaryReader reader) =>
      ArtifactRef(kind: reader.readString(), id: reader.readString());

  @override
  void write(BinaryWriter writer, ArtifactRef obj) {
    writer.writeString(obj.kind);
    writer.writeString(obj.id);
  }
}

/// Adapter for [SessionInfo].
class SessionInfoAdapter extends TypeAdapter<SessionInfo> {
  @override
  final int typeId = HiveTypeIds.sessionInfo;

  @override
  SessionInfo read(BinaryReader reader) => SessionInfo(
        id: reader.readString(),
        name: reader.readString(),
        createdAt: DateTime.parse(reader.readString()),
        updatedAt: DateTime.parse(reader.readString()),
        metadata: _readStringMap(reader),
      );

  @override
  void write(BinaryWriter writer, SessionInfo obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
    writer.writeMap(obj.metadata);
  }
}
