// GENERATED STUB — hand-stepped (spec 115 A6): the pinned channel
// contract; asserts method names and argument shapes.
// ignore_for_file: non_constant_identifier_names
library;

const String a6ChannelName = 'dev.zuraffa/agent_platform';
const List<String> a6MethodNames = [
  'getAgentHome',
  'secureRead',
  'secureWrite',
  'secureDelete',
];

String subject_a6(String method, Map<String, dynamic> args) {
  if (!a6MethodNames.contains(method)) return 'bad-method';
  switch (method) {
    case 'getAgentHome':
      return args.isEmpty ? 'ok' : 'bad-args';
    case 'secureRead':
    case 'secureDelete':
      return args.keys.contains('key') ? 'ok' : 'bad-args';
    case 'secureWrite':
      return args.keys.contains('key') && args.keys.contains('value')
          ? 'ok'
          : 'bad-args';
  }
  return 'bad-method';
}
