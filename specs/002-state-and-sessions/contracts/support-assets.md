# Contract: Support Assets (`zuraffa_agent`)

**Feature**: `002-state-and-sessions`

Ported pi_agent assets outside the session/compaction core. Signatures are
unchanged from the source (attribution headers carry provenance); deltas are
marked NEW.

## Tools (`tools.dart` — ported; consumed fully by spec 003)

```dart
class AgentTool<TParameters, TDetails> {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;      // JSON Schema
  final String label;
  final Map<String, dynamic>? Function(Map<String, dynamic>)? prepareArguments;
  final Future<AgentToolResult<TDetails>> Function(String toolCallId,
      Map<String, dynamic> params,
      {void Function(TDetails)? onUpdate, bool Function()? isAborted}) execute;
  final ToolExecutionMode? executionMode;
  Map<String, dynamic> toApiFormat();
}

List<String>? validateParameters(Map<String, dynamic> schema, Map<String, dynamic> values);
// Supports: type, properties, required, enum, items, additionalProperties,
// minimum/maximum, minLength/maxLength. Returns error list or null.
```

pi_agent's `typedef AgentTool<T, D> = dynamic` in types.dart is dropped; the
real class is the only `AgentTool` (research R10).

## Skills (`skills.dart` — ported)

```dart
Future<List<Skill>> loadSkills(List<String> directories, {bool followSymlinks = true});
Future<List<Skill>> loadSourcedSkills<TSource>(List<({TSource source, String directory})> sourceDirs, ...);
String formatSkillInvocation(Skill skill);
String formatSkillsForSystemPrompt(List<Skill> skills);  // <available_skills> XML
```

`Skill { name, description, content, invocation?, hidden, sourcePath, diagnostics }`.
Discovery: files named `SKILL.md` or `*.skill.md` (case-insensitive),
YAML-ish frontmatter with `name`, `description`, optional `invocation`,
`hidden`.

## Prompt templates (`prompt_templates.dart` — ported)

```dart
Future<List<PromptTemplate>> loadPromptTemplates(List<String> paths);
Future<List<PromptTemplate>> loadSourcedPromptTemplates<TSource>(...);
String substituteArgs(String content, List<String> args);   // $1..$N, $@, $ARGUMENTS, ${@:N}
List<String> parseCommandArgs(String input);                 // shell-style quoting
String formatPromptTemplateInvocation(PromptTemplate template, {List<String>? args, String? arguments});
```

## ExecutionEnv (`execution_env.dart` — ported)

```dart
abstract class ExecutionEnv {  // filesystem + shell abstraction
  Future<String> readFile(String path);
  Future<void> writeFile(String path, String content);
  Future<List<String>> listDirectory(String path);
  Future<void> removeFile(String path);
  Future<FileInfo> fileInfo(String path);
  Future<bool> fileExists(String path);
  Future<ShellResult> exec(String command, {String? workingDirectory,
      Map<String, String>? environment, bool Function()? isAborted});
  Future<String> createTempFile({String? prefix, String? suffix});
  Future<String> createTempDirectory({String? prefix});
}
class LocalExecutionEnv implements ExecutionEnv { ... }
String truncateHead/truncateTail(String text, {int? maxLines, int? maxBytes});
String formatSize(int bytes);
```

`FileError` / `FileErrorCode` typed failures; no exceptions for expected
missing files where a bool/exists API fits.

## SSE parser (`sse_parser.dart` — ported)

```dart
Stream<Map<String, String>> parseSSE(Stream<List<int>> byteStream);
// Emits {data, event?, id?, retry?} maps; handles multi-line data,
// ':' comments, chunked input, and final unterminated event on done.
```

Consumed by spec 004's streaming provider clients.

## UsageLedger projection (NEW — `usage_ledger.dart`)

```dart
class UsageLedger {
  factory UsageLedger.fromEntries(List<UsageLedgerEntry> entries); // branch-filtered upstream
  int get totalInputTokens;
  int get totalOutputTokens;
  Map<int, UsageLedgerEntry> byTurn();
  Map<String, int> byModel(); // modelId → total tokens
}
```

Consumed by the plugin policy shell's MissionBudgetHook
(arrrrny/zuraffa#387); per-call records persist as `UsageLedgerEntry` tree
entries (data-model.md).

## Attribution contract (all ported files)

```dart
// Ported from pi_agent (~/Developer/pi/pi_agent, branch 001-dart-agent-package).
// Source licensed MIT; modifications licensed MIT under zuraffa_agent.
```

Every file listed above carries this header; LICENSE/NOTICE records the
provenance for the package as a whole (US4 AC, FR-005).
