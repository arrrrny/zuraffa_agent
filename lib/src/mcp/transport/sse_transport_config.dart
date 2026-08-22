/// SSE Transport Configuration — configuration for MCP over SSE with Bearer auth and reconnect policy.
library;

import 'package:json_annotation/json_annotation.dart';

import 'reconnect_policy.dart';

part 'sse_transport_config.g.dart';

@JsonSerializable()
class SseTransportConfig {
  SseTransportConfig({
    required this.endpoint,
    required this.bearerToken,
    required this.reconnectPolicy,
  });

  factory SseTransportConfig.fromJson(Map<String, dynamic> json) =>
      _$SseTransportConfigFromJson(json);

  final String endpoint;
  final String bearerToken;
  final ReconnectPolicy reconnectPolicy;

  SseTransportConfig copyWith({
    String? endpoint,
    String? bearerToken,
    ReconnectPolicy? reconnectPolicy,
  }) {
    return SseTransportConfig(
      endpoint: endpoint ?? this.endpoint,
      bearerToken: bearerToken ?? this.bearerToken,
      reconnectPolicy: reconnectPolicy ?? this.reconnectPolicy,
    );
  }

  Map<String, dynamic> toJson() => _$SseTransportConfigToJson(this);
}