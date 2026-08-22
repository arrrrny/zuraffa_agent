/// Reconnect Policy — configuration for SSE reconnect behavior.
library;

import 'package:json_annotation/json_annotation.dart';

part 'reconnect_policy.g.dart';

@JsonSerializable()
class ReconnectPolicy {
  ReconnectPolicy({
    required this.baseDelayMs,
    required this.maxDelayMs,
    required this.multiplier,
    required this.jitterFactor,
    required this.maxRetries,
  });

  factory ReconnectPolicy.fromJson(Map<String, dynamic> json) =>
      _$ReconnectPolicyFromJson(json);

  final int baseDelayMs;
  final int maxDelayMs;
  final double multiplier;
  final double jitterFactor;
  final int maxRetries;

  ReconnectPolicy copyWith({
    int? baseDelayMs,
    int? maxDelayMs,
    double? multiplier,
    double? jitterFactor,
    int? maxRetries,
  }) {
    return ReconnectPolicy(
      baseDelayMs: baseDelayMs ?? this.baseDelayMs,
      maxDelayMs: maxDelayMs ?? this.maxDelayMs,
      multiplier: multiplier ?? this.multiplier,
      jitterFactor: jitterFactor ?? this.jitterFactor,
      maxRetries: maxRetries ?? this.maxRetries,
    );
  }

  Map<String, dynamic> toJson() => _$ReconnectPolicyToJson(this);
}