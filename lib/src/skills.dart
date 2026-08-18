// Ported from pi_agent (https://github.com/badlogic/pi_agent)
// Original work Copyright (c) 2024 Mario Zechner
// Modified work Copyright (c) 2026 ZikZak AI / Ahmet TOK
// Licensed under the MIT License. See LICENSE file in the project root.

// Skill discovery and system prompt formatting — hand-written engine glue.
//
// Discovers SKILL.md or *.skill.md files in a directory and renders them
// into system prompt blocks.

import 'dart:io';

/// Represents a discovered skill with name, description, and instructions.
class Skill {
  final String name;
  final String description;
  final String instructions;
  final String sourcePath;

  const Skill({
    required this.name,
    required this.description,
    required this.instructions,
    required this.sourcePath,
  });
}

/// Discovers skill definitions in [directoryPath].
///
/// Looks for files named `SKILL.md` or `*.skill.md`. Each file is expected
/// to have a YAML frontmatter block (between `---` delimiters) containing
/// at least `name` and `description` fields, followed by the skill
/// instructions in markdown.
List<Skill> loadSkills(String directoryPath) {
  final dir = Directory(directoryPath);
  if (!dir.existsSync()) return const [];

  final skills = <Skill>[];

  for (final entity in dir.listSync()) {
    if (entity is! File) continue;
    final name = entity.path.split(Platform.pathSeparator).last;
    if (name == 'SKILL.md' || name.endsWith('.skill.md')) {
      final skill = _parseSkillFile(entity);
      if (skill != null) skills.add(skill);
    }
  }

  return skills;
}

/// Renders a list of [Skill] instances into formatted system prompt blocks.
///
/// Each skill is rendered as:
/// ```
/// ## Skill: {name}
/// {description}
///
/// {instructions}
/// ```
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

Skill? _parseSkillFile(File file) {
  try {
    final content = file.readAsStringSync();
    final lines = content.split('\n');

    // Parse YAML frontmatter between --- delimiters.
    if (lines.isEmpty || lines.first.trim() != '---') return null;

    final frontmatterEnd = lines.indexOf('---', 1);
    if (frontmatterEnd == -1) return null;

    String name = '';
    String description = '';

    for (var i = 1; i < frontmatterEnd; i++) {
      final line = lines[i];
      if (line.startsWith('name:')) {
        name = line.substring(5).trim().replaceAll(RegExp(r'^["\x27]|["\x27]$'), '');
      } else if (line.startsWith('description:')) {
        description = line.substring(12).trim().replaceAll(RegExp(r'^["\x27]|["\x27]$'), '');
      }
    }

    if (name.isEmpty) return null;

    // Instructions are everything after the frontmatter.
    final instructions = lines.sublist(frontmatterEnd + 1).join('\n').trim();

    return Skill(
      name: name,
      description: description,
      instructions: instructions,
      sourcePath: file.path,
    );
  } catch (_) {
    return null;
  }
}
