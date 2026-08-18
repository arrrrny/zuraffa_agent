// Ported from pi_agent (~/Developer/pi/pi_agent, branch 001-dart-agent-package,
// test/tools_test.dart). Source licensed BSD-3-Clause (ZikZak AI);
// modifications licensed MIT under zuraffa_agent.
import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() {
  group('AgentTool', () {
    test('constructs with required fields', () {
      final tool = AgentTool<String, String>(
        name: 'get_weather',
        description: 'Get weather for a city',
        parameters: {
          'type': 'object',
          'properties': {
            'city': {'type': 'string', 'description': 'City name'},
          },
          'required': ['city'],
        },
        execute: (id, params, {onUpdate, isAborted}) async => AgentToolResult(
          content: [const TextBlock('Sunny')],
          details: 'sunny',
        ),
      );

      expect(tool.name, 'get_weather');
      expect(tool.description, 'Get weather for a city');
      expect(tool.label, '');
      expect(tool.executionMode, isNull);
    });

    test('toApiFormat produces correct structure', () {
      final tool = AgentTool<String, String>(
        name: 'search',
        description: 'Search the web',
        parameters: {'type': 'object', 'properties': {}},
        execute: (id, params, {onUpdate, isAborted}) async => AgentToolResult(
          content: [const TextBlock('')],
          details: '',
        ),
      );

      final api = tool.toApiFormat();
      expect(api['type'], 'function');
      expect((api['function'] as Map<String, dynamic>)['name'], 'search');
      expect((api['function'] as Map<String, dynamic>)['parameters'],
          isA<Map<String, dynamic>>());
    });

    test('prepareArguments and executionMode fields exist', () {
      Map<String, dynamic>? prepared(Map<String, dynamic> args) => args;
      final tool = AgentTool<String, String>(
        name: 't',
        description: 'd',
        parameters: {},
        prepareArguments: prepared,
        executionMode: ToolExecutionMode.sequential,
        execute: (id, params, {onUpdate, isAborted}) async => AgentToolResult(
          content: [],
          details: '',
        ),
      );
      expect(tool.prepareArguments, isNotNull);
      expect(tool.executionMode, ToolExecutionMode.sequential);
    });

    test('execute returns result', () {
      final tool = AgentTool<String, String>(
        name: 'echo',
        description: 'Echo input',
        parameters: {'type': 'object', 'properties': {}},
        execute: (id, params, {onUpdate, isAborted}) async => AgentToolResult(
          content: [TextBlock(params['msg'] as String)],
          details: 'ok',
        ),
      );

      final result = tool.execute('tc-1', {'msg': 'hello'});
      expect(result, isA<Future<AgentToolResult<String>>>());
    });

    test('execute resolves with content and terminate flag', () async {
      final tool = AgentTool<String, String>(
        name: 'stop',
        description: 'Stop',
        parameters: {},
        execute: (id, params, {onUpdate, isAborted}) async => AgentToolResult(
          content: [const TextBlock('done')],
          details: '',
          terminate: true,
        ),
      );

      final result = await tool.execute('tc-1', {});
      expect(result.terminate, true);
      expect(switch (result.content.first) {
        TextBlock(text: final t) => t,
        _ => fail('expected TextBlock'),
      }, 'done');
    });
  });

  group('validateParameters', () {
    test('returns null for valid simple object', () {
      final schema = {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
          'age': {'type': 'integer'},
        },
        'required': ['name'],
      };
      final values = {'name': 'Alice', 'age': 30};
      expect(validateParameters(schema, values), isNull);
    });

    test('returns errors for missing required field', () {
      final schema = {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
        'required': ['name'],
      };
      final errors = validateParameters(schema, {});
      expect(errors, isNotNull);
      expect(errors!, anyElement(contains('required field missing')));
    });

    test('returns errors for wrong type', () {
      final schema = {
        'type': 'object',
        'properties': {
          'age': {'type': 'integer'},
        },
      };
      final errors = validateParameters(schema, {'age': 'not a number'});
      expect(errors, isNotNull);
      expect(errors!, anyElement(contains('expected integer')));
    });

    test('validates nested objects', () {
      final schema = {
        'type': 'object',
        'properties': {
          'address': {
            'type': 'object',
            'properties': {
              'city': {'type': 'string'},
            },
            'required': ['city'],
          },
        },
      };
      final errors = validateParameters(schema, {
        'address': {'city': 123},
      });
      expect(errors, isNotNull);
      expect(errors!, anyElement(contains('expected string')));
    });

    test('validates arrays with items schema', () {
      final schema = {
        'type': 'object',
        'properties': {
          'tags': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
      };
      expect(
          validateParameters(schema, {
            'tags': ['a', 'b']
          }),
          isNull);
      final errors = validateParameters(schema, {
        'tags': ['a', 123]
      });
      expect(errors, isNotNull);
      expect(errors!, anyElement(contains('expected string')));
    });

    test('validates enum constraint', () {
      final schema = {
        'type': 'object',
        'properties': {
          'color': {
            'type': 'string',
            'enum': ['red', 'green', 'blue']
          },
        },
      };
      expect(validateParameters(schema, {'color': 'red'}), isNull);
      final errors = validateParameters(schema, {'color': 'yellow'});
      expect(errors, isNotNull);
      expect(errors!, anyElement(contains('must be one of')));
    });

    test('validates minimum/maximum for numbers', () {
      final schema = {
        'type': 'object',
        'properties': {
          'score': {'type': 'number', 'minimum': 0, 'maximum': 100},
        },
      };
      expect(validateParameters(schema, {'score': 50}), isNull);
      expect(validateParameters(schema, {'score': -1}), isNotNull);
      expect(validateParameters(schema, {'score': 101}), isNotNull);
    });

    test('validates minLength/maxLength for strings', () {
      final schema = {
        'type': 'object',
        'properties': {
          'name': {'type': 'string', 'minLength': 2, 'maxLength': 10},
        },
      };
      expect(validateParameters(schema, {'name': 'Alice'}), isNull);
      expect(validateParameters(schema, {'name': 'A'}), isNotNull);
      expect(validateParameters(schema, {'name': 'A' * 11}), isNotNull);
    });

    test('validates additionalProperties false', () {
      final schema = {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
        'additionalProperties': false,
      };
      expect(validateParameters(schema, {'name': 'ok'}), isNull);
      final errors = validateParameters(schema, {'name': 'ok', 'extra': 'bad'});
      expect(errors, isNotNull);
      expect(errors!, anyElement(contains('additional property not allowed')));
    });

    test('returns null for empty schema', () {
      expect(validateParameters({}, {'anything': 'goes'}), isNull);
    });

    test('returns null for boolean type', () {
      final schema = {
        'type': 'object',
        'properties': {
          'active': {'type': 'boolean'},
        },
      };
      expect(validateParameters(schema, {'active': true}), isNull);
      expect(validateParameters(schema, {'active': 'yes'}), isNotNull);
    });

    test('returns null for number type accepting int and double', () {
      final schema = {
        'type': 'object',
        'properties': {
          'x': {'type': 'number'},
        },
      };
      expect(validateParameters(schema, {'x': 42}), isNull);
      expect(validateParameters(schema, {'x': 3.14}), isNull);
    });
  });
}
