# Interface Contract: Ported Support Assets & Attribution

**Feature**: `001-state-and-sessions`  
**Date**: 2026-08-18  
**Spec**: [spec.md](../spec.md)

---

## 1. Attribution Header Requirement

All files ported from `pi_agent` must carry the standard MIT attribution header at the very top of the file:

```dart
// Ported from pi_agent (https://github.com/badlogic/pi_agent)
// Original work Copyright (c) 2024 Mario Zechner
// Modified work Copyright (c) 2026 ZikZak AI / Ahmet TOK
// Licensed under the MIT License. See LICENSE file in the project root.
```

---

## 2. Ported Asset Modules & Interfaces

### 2.1 Tool Validation & Definition (`lib/src/tools.dart`)
- `AgentTool<TParameters, TDetails>`: Class representing executable agent tools.
- `validateParameters(Map<String, dynamic> schema, Map<String, dynamic> params)`: JSON-Schema subset parameter validator supporting types, objects, arrays, bounds, and enums.

### 2.2 Skill Discovery & Formatting (`lib/src/skills.dart`)
- `loadSkills(String directoryPath)`: Discovers `SKILL.md` or `*.skill.md` definitions.
- `formatSkillsForSystemPrompt(List<Skill> skills)`: Renders skills into system prompt blocks.

### 2.3 Prompt Template Engine (`lib/src/prompt_templates.dart`)
- `loadPromptTemplates(String directoryPath)`: Discovers prompt template files.
- `substituteArgs(String template, List<String> positionalArgs, Map<String, String> namedArgs)`: Substitutes `$1..$N`, `$@`, and `$ARGUMENTS` variables.

### 2.4 Execution Environment (`lib/src/execution_env.dart`)
- `ExecutionEnv`: Abstract filesystem and shell abstraction.
- `LocalExecutionEnv`: Pure Dart local implementation supporting safe reads, file metadata, head/tail truncation, and subprocess execution.

### 2.5 Server-Sent Events Parser (`lib/src/sse_parser.dart`)
- `parseSSE(Stream<List<int>> byteStream)`: Transforms HTTP chunked byte streams into structured SSE event maps.
