/// Stdio Transport Configuration — configuration for MCP over stdio with process management.
library;

import 'package:json_annotation/json_annotation.dart';

import 'restart_policy.dart';

part 'stdio_transport_config.g.dart';

@JsonSerializable()
class StdioTransportConfig {
  StdioTransportConfig({
    required this.command,
    required this.args,
    required this.env,
    required this.restartPolicy,
  });

  factory StdioTransportConfig.fromJson(Map<String, dynamic> json) =>
      _$StdioTransportConfigFromJson(json);

  final String command;
  final List<String> args;
  final Map<String, String> env;
  final RestartPolicy restartPolicy;

  StdioTransportConfig copyWith({
    String? command,
    List<String>? args,
    Map<String, String>? env,
    RestartPolicy? restartPolicy,
  }) {
    return StdioTransportConfig(
      command: command ?? this.command,
      args: args ?? this.args,
      env: env ?? this.env,
      restartPolicy: restartPolicy ?? this.restartPolicy,
    );
  }

  Map<String, dynamic> toJson() => _$StdioTransportConfigToJson(this);
}