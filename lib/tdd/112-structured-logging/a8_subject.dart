// Hand-stepped acceptance subject (spec 112, AC-8): given the lib/
// source files (read by the test), return the files containing console
// output calls — the engine never prints.
// ignore_for_file: non_constant_identifier_names
library;

List<String> subject_a8(Map<String, String> sources) {
  // Console-output calls only: `print(` and top-level
  // `stdout./stderr.` writes — `process.stdout` field accesses on a
  // child process (the stdio MCP transport) are protocol plumbing,
  // not printing.
  final patterns = [
    RegExp(r'\bprint\('),
    RegExp(r'(?<![.\w])stdout\s*\.\s*(write|writeln|add|addStream)'),
    RegExp(r'(?<![.\w])stderr\s*\.\s*(write|writeln|add|addStream)'),
  ];
  final offenders = <String>[];
  sources.forEach((path, content) {
    for (final line in content.split('\n')) {
      final code = line.trimLeft().startsWith('//') ? '' : line;
      if (patterns.any((p) => p.hasMatch(code))) {
        offenders.add(path);
        break;
      }
    }
  });
  return offenders;
}
