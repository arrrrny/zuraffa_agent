// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stdio_transport_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StdioTransportConfig _$StdioTransportConfigFromJson(
  Map<String, dynamic> json,
) => StdioTransportConfig(
  command: json['command'] as String,
  args: (json['args'] as List<dynamic>).map((e) => e as String).toList(),
  env: Map<String, String>.from(json['env'] as Map),
  restartPolicy: RestartPolicy.fromJson(
    json['restartPolicy'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$StdioTransportConfigToJson(
  StdioTransportConfig instance,
) => <String, dynamic>{
  'command': instance.command,
  'args': instance.args,
  'env': instance.env,
  'restartPolicy': instance.restartPolicy,
};
