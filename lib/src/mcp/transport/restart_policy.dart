/// Restart Policy — configuration for stdio process restart behavior.
library;

import 'package:json_annotation/json_annotation.dart';

part 'restart_policy.g.dart';

@JsonSerializable()
class RestartPolicy {
  RestartPolicy({
    required this.maxRetries,
    required this.backoffDelaysMs,
  });

  factory RestartPolicy.fromJson(Map<String, dynamic> json) =>
      _$RestartPolicyFromJson(json);

  final int maxRetries;
  final List<int> backoffDelaysMs;

  RestartPolicy copyWith({
    int? maxRetries,
    List<int>? backoffDelaysMs,
  }) {
    return RestartPolicy(
      maxRetries: maxRetries ?? this.maxRetries,
      backoffDelaysMs: backoffDelaysMs ?? this.backoffDelaysMs,
    );
  }

  Map<String, dynamic> toJson() => _$RestartPolicyToJson(this);
}