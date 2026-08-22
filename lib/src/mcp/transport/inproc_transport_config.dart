/// InProc Transport Configuration — configuration for in-proc MCP transport (direct registry calls).
library;

import 'package:json_annotation/json_annotation.dart';

part 'inproc_transport_config.g.dart';

@JsonSerializable()
class InProcTransportConfig {
  InProcTransportConfig({required this.registryId});

  factory InProcTransportConfig.fromJson(Map<String, dynamic> json) =>
      _$InProcTransportConfigFromJson(json);

  final String registryId;

  InProcTransportConfig copyWith({String? registryId}) {
    return InProcTransportConfig(registryId: registryId ?? this.registryId);
  }

  Map<String, dynamic> toJson() => _$InProcTransportConfigToJson(this);
}