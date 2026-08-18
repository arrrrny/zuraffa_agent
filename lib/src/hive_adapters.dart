// Hive binary TypeAdapters for zfa-generated entity types.
//
// This file is integration glue: hand-written against zfa-generated entity
// types (TurnRecord, ToolInvocationRecord, UsageLedgerEntry, CompactionEntry,
// CompactionSummary, Model, ArtifactRef, etc.).

import 'dart:convert';

import 'package:hive_ce/hive.dart';

import 'types.dart';

/// TypeAdapter for [SessionTreeEntry] that delegates to per-subtype
/// JSON serialization. Hive stores entries as JSON bytes with a type tag.
class SessionTreeEntryAdapter extends TypeAdapter<SessionTreeEntry> {
  @override
  final int typeId;

  SessionTreeEntryAdapter(this.typeId);

  @override
  SessionTreeEntry read(BinaryReader reader) {
    final json = jsonDecode(reader.readString()) as Map<String, dynamic>;
    return SessionTreeEntry.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, SessionTreeEntry obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

/// TypeAdapter for [Model] value object.
class ModelAdapter extends TypeAdapter<Model> {
  @override
  final int typeId;

  ModelAdapter(this.typeId);

  @override
  Model read(BinaryReader reader) {
    final json = jsonDecode(reader.readString()) as Map<String, dynamic>;
    return Model.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, Model obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

/// TypeAdapter for [AgentMessage] sealed hierarchy.
class AgentMessageAdapter extends TypeAdapter<AgentMessage> {
  @override
  final int typeId;

  AgentMessageAdapter(this.typeId);

  @override
  AgentMessage read(BinaryReader reader) {
    final json = jsonDecode(reader.readString()) as Map<String, dynamic>;
    return AgentMessage.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, AgentMessage obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

/// TypeAdapter for [ContentBlock] sealed hierarchy.
class ContentBlockAdapter extends TypeAdapter<ContentBlock> {
  @override
  final int typeId;

  ContentBlockAdapter(this.typeId);

  @override
  ContentBlock read(BinaryReader reader) {
    final json = jsonDecode(reader.readString()) as Map<String, dynamic>;
    return ContentBlock.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, ContentBlock obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

/// Registers all zuraffa entity TypeAdapters with a Hive [box].
///
/// Call this before opening any entity boxes:
/// ```dart
/// registerZuraffaAdapters();
/// final box = await Hive.openBox<SessionTreeEntry>('entries');
/// ```
void registerZuraffaAdapters() {
  // Use sequential typeIds starting after Hive's built-in adapters (0-19).
  Hive.registerAdapter(SessionTreeEntryAdapter(20));
  Hive.registerAdapter(ModelAdapter(21));
  Hive.registerAdapter(AgentMessageAdapter(22));
  Hive.registerAdapter(ContentBlockAdapter(23));
}
