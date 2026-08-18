// Ported from pi_agent (https://github.com/badlogic/pi_agent)
// Original work Copyright (c) 2024 Mario Zechner
// Modified work Copyright (c) 2026 ZikZak AI / Ahmet TOK
// Licensed under the MIT License. See LICENSE file in the project root.

// Tool validation and definition — hand-written engine glue.
//
// Provides AgentTool definition and JSON-Schema subset parameter validation.

/// Represents an executable agent tool with typed parameters.
class AgentTool<TParameters, TDetails> {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
  final Future<TDetails> Function(TParameters params)? execute;

  const AgentTool({
    required this.name,
    required this.description,
    required this.inputSchema,
    this.execute,
  });
}

/// Validates a parameter map against a JSON-Schema subset definition.
///
/// Supports: type (string, number, integer, boolean, array, object),
/// required fields, enum constraints, minimum/maximum bounds, and
/// nested object properties.
///
/// Returns a list of validation error messages. An empty list means valid.
List<String> validateParameters(
  Map<String, dynamic> schema,
  Map<String, dynamic> params,
) {
  final errors = <String>[];

  // Check required fields.
  final required = schema['required'] as List?;
  if (required != null) {
    for (final field in required) {
      if (!params.containsKey(field)) {
        errors.add('Missing required field: $field');
      }
    }
  }

  // Validate properties against their schemas.
  final properties = schema['properties'] as Map<String, dynamic>?;
  if (properties != null) {
    for (final entry in properties.entries) {
      final fieldSchema = entry.value as Map<String, dynamic>;
      final fieldName = entry.key;

      if (!params.containsKey(fieldName)) continue;

      final value = params[fieldName];
      final fieldType = fieldSchema['type'] as String?;

      // Type validation.
      if (fieldType != null && !_typeMatches(value, fieldType)) {
        errors.add('Field $fieldName: expected $fieldType, got ${value.runtimeType}');
        continue;
      }

      // Enum validation.
      final enumValues = fieldSchema['enum'] as List?;
      if (enumValues != null && !enumValues.contains(value)) {
        errors.add('Field $fieldName: value must be one of $enumValues');
      }

      // Number bounds.
      if (fieldType == 'number' || fieldType == 'integer') {
        if (value is num) {
          final minimum = fieldSchema['minimum'] as num?;
          final maximum = fieldSchema['maximum'] as num?;
          if (minimum != null && value < minimum) {
            errors.add('Field $fieldName: must be >= $minimum');
          }
          if (maximum != null && value > maximum) {
            errors.add('Field $fieldName: must be <= $maximum');
          }
        }
      }

      // Array items validation.
      if (fieldType == 'array' && value is List) {
        final items = fieldSchema['items'] as Map<String, dynamic>?;
        if (items != null) {
          final itemType = items['type'] as String?;
          if (itemType != null) {
            for (var i = 0; i < value.length; i++) {
              if (!_typeMatches(value[i], itemType)) {
                errors.add(
                  'Field $fieldName[$i]: expected $itemType, got ${value[i].runtimeType}',
                );
              }
            }
          }
        }
      }

      // Nested object validation.
      if (fieldType == 'object' && value is Map<String, dynamic>) {
        final nestedSchema = fieldSchema['properties'] as Map<String, dynamic>?;
        if (nestedSchema != null) {
          errors.addAll(validateParameters(
            {'properties': nestedSchema},
            value,
          ));
        }
      }
    }
  }

  return errors;
}

bool _typeMatches(dynamic value, String expectedType) {
  switch (expectedType) {
    case 'string':
      return value is String;
    case 'number':
      return value is num;
    case 'integer':
      return value is int;
    case 'boolean':
      return value is bool;
    case 'array':
      return value is List;
    case 'object':
      return value is Map;
    default:
      return true; // Unknown type — pass through.
  }
}
