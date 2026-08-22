// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sse_transport_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SseTransportConfig _$SseTransportConfigFromJson(Map<String, dynamic> json) =>
    SseTransportConfig(
      endpoint: json['endpoint'] as String,
      bearerToken: json['bearerToken'] as String,
      reconnectPolicy: ReconnectPolicy.fromJson(
        json['reconnectPolicy'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$SseTransportConfigToJson(SseTransportConfig instance) =>
    <String, dynamic>{
      'endpoint': instance.endpoint,
      'bearerToken': instance.bearerToken,
      'reconnectPolicy': instance.reconnectPolicy,
    };
