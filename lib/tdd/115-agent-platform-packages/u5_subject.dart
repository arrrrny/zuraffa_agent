// GENERATED STUB — hand-stepped (spec 115 U5): the pinned channel
// contract surface. The test asserts the interface package source pins
// these names (the live channel proof runs under `flutter test`).
// ignore_for_file: non_constant_identifier_names
library;

const String u5ChannelName = 'dev.zuraffa/agent_platform';
const List<String> u5MethodNames = [
  'getAgentHome',
  'secureRead',
  'secureWrite',
  'secureDelete',
];
const List<String> u5ArgKeys = ['key', 'value'];

/// subject_u5: declared contract `channel(method, args) -> Outcome`.
///
/// Returns 'ok' when [method]/[args] match the pinned contract.
String subject_u5(String? method, Map<String, dynamic>? args) {
  if (!u5MethodNames.contains(method)) return 'bad-method';
  final keys = args?.keys.toSet() ?? <String>{};
  switch (method) {
    case 'getAgentHome':
      return keys.isEmpty ? 'ok' : 'bad-args';
    case 'secureRead':
    case 'secureDelete':
      return keys.contains('key') ? 'ok' : 'bad-args';
    case 'secureWrite':
      return (keys.contains('key') && keys.contains('value'))
          ? 'ok'
          : 'bad-args';
  }
  return 'bad-method';
}
