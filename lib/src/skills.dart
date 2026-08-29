// Ported from pi_agent (https://github.com/pi_agent)
// Original work Copyright (c) 2024 Mario Zechner
// Modified work Copyright (c) 2026 ZikZak AI / Ahmet TOK
// Licensed under the MIT License. See LICENSE file in the project root.

// Skill discovery and system prompt formatting — R1 engine core (spec 079).
//
// Discovers SKILL.md or *.skill.md files in a directory and renders them
// into system prompt blocks. The parse transform is a PURE function
// (no I/O) so it can be reused on content from any source; `loadSkills`
// is the I/O boundary that walks a directory and delegates each file's
// content to `parseSkill`. Malformed frontmatter surfaces as a typed
// `SkillFormatException` — never silently swallowed.

import 'dart:io';
import 'package:yaml/yaml.dart';

/// Thrown when a skill file's frontmatter is malformed.
///
/// Extends [FormatException] so it slots into Dart's standard hierarchy
/// for malformed textual input; engine integration can catch
/// [SkillFormatException] specifically or fall through to
/// [FormatException].
class SkillFormatException extends FormatException {
  /// Path of the offending file (or the `sourcePath` passed to
  /// [parseSkill]).
  final String sourcePath;

  /// Short machine-readable reason code:
  /// `missing-opening-delimiter`, `missing-closing-delimiter`,
  /// `missing-name`, `frontmatter-not-a-map`, `yaml-parse-error`,
  /// or `io-error` (when an underlying I/O error is wrapped).
  final String reason;

  SkillFormatException(this.sourcePath, this.reason, [Object? parsed])
      : super(
          'Skill file at "$sourcePath" has malformed frontmatter: $reason'
          '${parsed != null ? ' (near: $parsed)' : ''}',
        );
}

/// Represents a discovered skill with name, description, instructions,
/// and any extra frontmatter metadata.
class Skill {
  /// Skill name from the `name:` frontmatter field. Required.
  final String name;

  /// Skill description from the `description:` frontmatter field.
  /// Empty string when the field is absent.
  final String description;

  /// Markdown body after the closing `---` delimiter, trimmed of
  /// leading/trailing whitespace. Empty string when the body is empty.
  final String instructions;

  /// Path of the file this skill was parsed from (echoed from the
  /// `sourcePath` argument to [parseSkill]).
  final String sourcePath;

  /// Every frontmatter key other than `name` and `description`,
  /// preserved as-is from the YAML parse. Defensive copy — mutating
  /// this map does not affect a future [parseSkill] call on the same
  /// input. Empty map when the frontmatter declares only
  /// `name`/`description`.
  final Map<String, Object?> metadata;

  const Skill({
    required this.name,
    required this.description,
    required this.instructions,
    required this.sourcePath,
    this.metadata = const <String, Object?>{},
  });
}

/// Parses a skill definition from its raw text content.
///
/// Pure transform — no I/O, no `Future`, no side effects. Same
/// `content` + `sourcePath` always produce the same [Skill] (modulo
/// the `sourcePath` field, which is echoed back on the result).
///
/// Throws [SkillFormatException] when:
/// - the content does not start with `---` (`missing-opening-delimiter`);
/// - the opening `---` has no matching closing `---`
///   (`missing-closing-delimiter`);
/// - the YAML between the delimiters cannot be parsed
///   (`yaml-parse-error`);
/// - the frontmatter parses to something other than a YAML map
///   (`frontmatter-not-a-map`);
/// - the `name:` field is missing or not a string (`missing-name`).
///
/// The `description:` field is optional — when absent or not a string,
/// the [Skill.description] is the empty string.
Skill parseSkill(String content, {required String sourcePath}) {
  // Split frontmatter on `---` delimiters. We honor the convention
  // that the file starts with `---` on its own first line.
  final lines = content.split('\n');

  if (lines.isEmpty || lines.first.trim() != '---') {
    throw SkillFormatException(sourcePath, 'missing-opening-delimiter');
  }

  // Find the closing `---`. Search starting from the second line so
  // we don't match the opener again.
  var closingIndex = -1;
  for (var i = 1; i < lines.length; i++) {
    if (lines[i].trim() == '---') {
      closingIndex = i;
      break;
    }
  }
  if (closingIndex == -1) {
    throw SkillFormatException(sourcePath, 'missing-closing-delimiter');
  }

  final frontmatterYaml = lines.sublist(1, closingIndex).join('\n');
  final body = lines.sublist(closingIndex + 1).join('\n').trim();

  // Parse the frontmatter YAML.
  final dynamic yamlLoaded;
  try {
    yamlLoaded = loadYaml(frontmatterYaml);
  } catch (e) {
    throw SkillFormatException(sourcePath, 'yaml-parse-error', e);
  }

  if (yamlLoaded is! YamlMap) {
    // Frontmatter is a scalar/list/empty — not a map.
    throw SkillFormatException(sourcePath, 'frontmatter-not-a-map');
  }
  final yamlMap = yamlLoaded;

  // Extract `name` (required).
  final nameRaw = yamlMap['name'];
  if (nameRaw is! String) {
    throw SkillFormatException(sourcePath, 'missing-name');
  }

  // Extract `description` (optional; non-string or absent → '').
  final descRaw = yamlMap['description'];
  final description = descRaw is String ? descRaw : '';

  // Build the metadata map: every key other than `name`/`description`.
  // Defensive copy via Map<String, Object?>.from so callers can mutate
  // the returned map without affecting the YAML node or future parses.
  final metadata = <String, Object?>{};
  for (final entry in yamlMap.entries) {
    final key = entry.key;
    if (key == 'name' || key == 'description') continue;
    metadata[key.toString()] = _coerceYamlValue(entry.value);
  }

  return Skill(
    name: nameRaw,
    description: description,
    instructions: body,
    sourcePath: sourcePath,
    metadata: metadata,
  );
}

/// Coerces a YAML node value into a plain Dart object so the
/// returned `Skill.metadata` map is not tied to the `yaml` package's
/// internal node types. Recurses into maps and lists.
Object? _coerceYamlValue(Object? value) {
  if (value is YamlMap) {
    final out = <String, Object?>{};
    for (final entry in value.entries) {
      out[entry.key.toString()] = _coerceYamlValue(entry.value);
    }
    return out;
  }
  if (value is YamlList) {
    return [for (final item in value) _coerceYamlValue(item)];
  }
  // Scalar (String, int, double, bool, null) — pass through.
  return value;
}

/// Discovers skill definitions in [directoryPath].
///
/// Looks for files named `SKILL.md` or `*.skill.md` at the TOP LEVEL
/// of the directory (no recursion into subdirectories — callers
/// compose multiple directories themselves). Non-existent directory
/// returns `const []` (the engine's empty case, not an error).
///
/// Each discovered file is parsed via [parseSkill]. A malformed file
/// surfaces as a [SkillFormatException] propagated to the caller —
/// never silently dropped.
Future<List<Skill>> loadSkills(String directoryPath) async {
  final dir = Directory(directoryPath);
  if (!await dir.exists()) return const [];

  final skills = <Skill>[];

  await for (final entity in dir.list()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (name == 'SKILL.md' || name.endsWith('.skill.md')) {
      skills.add(await _parseSkillFile(entity));
    }
  }

  return skills;
}

/// Renders a list of [Skill] instances into formatted system prompt
/// blocks.
///
/// Each skill is rendered as:
/// ```
/// ## Skill: {name}
/// {description}
///
/// {instructions}
/// ```
/// Skills are separated by a blank line; an empty list renders as the
/// empty string.
String formatSkillsForSystemPrompt(List<Skill> skills) {
  if (skills.isEmpty) return '';

  final buf = StringBuffer();
  for (var i = 0; i < skills.length; i++) {
    final skill = skills[i];
    if (i > 0) buf.writeln();
    buf.writeln('## Skill: ${skill.name}');
    buf.writeln(skill.description);
    buf.writeln();
    buf.writeln(skill.instructions);
  }

  return buf.toString();
}

Future<Skill> _parseSkillFile(File file) async {
  try {
    final content = await file.readAsString();
    return parseSkill(content, sourcePath: file.path);
  } on SkillFormatException {
    // Re-throw — malformed frontmatter surfaces to the caller (FR-002).
    rethrow;
  } catch (e) {
    // Genuine I/O error (file vanished mid-walk, permission denied, etc.).
    // Wrap as SkillFormatException so callers have a single typed
    // exception to catch.
    throw SkillFormatException(file.path, 'io-error', e);
  }
}
