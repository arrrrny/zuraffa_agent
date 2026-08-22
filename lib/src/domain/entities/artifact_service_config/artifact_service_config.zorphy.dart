// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'artifact_service_config.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class ArtifactServiceConfig {
  ArtifactServiceConfig({required int this.thresholdBytes});

  factory ArtifactServiceConfig.fromJson(Map<String, dynamic> json) =>
      _$ArtifactServiceConfigFromJson(json);

  final int thresholdBytes;

  ArtifactServiceConfig copyWith({int? thresholdBytes}) {
    return ArtifactServiceConfig(
      thresholdBytes: thresholdBytes ?? this.thresholdBytes,
    );
  }

  ArtifactServiceConfig copyWithArtifactServiceConfig({int? thresholdBytes}) {
    return copyWith(thresholdBytes: thresholdBytes);
  }

  ArtifactServiceConfig patchWithArtifactServiceConfig([
    ArtifactServiceConfigPatch? patchInput,
  ]) {
    final _patcher = patchInput ?? ArtifactServiceConfigPatch();
    final _patchMap = _patcher.patchMap;
    return ArtifactServiceConfig(
      thresholdBytes:
          _patchMap.containsKey(ArtifactServiceConfig$.thresholdBytes)
          ? ((_patchMap[ArtifactServiceConfig$.thresholdBytes] is Function)
                    ? _patchMap[ArtifactServiceConfig$.thresholdBytes](
                        this.thresholdBytes,
                      )
                    : (_patchMap[ArtifactServiceConfig$.thresholdBytes]
                          is Patch)
                    ? _patchMap[ArtifactServiceConfig$.thresholdBytes].applyTo(
                        this.thresholdBytes,
                      )
                    : _patchMap[ArtifactServiceConfig$.thresholdBytes])
                as int
          : this.thresholdBytes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArtifactServiceConfig &&
        thresholdBytes == other.thresholdBytes;
  }

  @override
  int get hashCode {
    return Object.hash(thresholdBytes, 0);
  }

  @override
  String toString() {
    return 'ArtifactServiceConfig(' + 'thresholdBytes: ${thresholdBytes})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ArtifactServiceConfigToJson(this);
    _sanitizeJson(data);
    return data;
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension ArtifactServiceConfigPropertyHelpers on ArtifactServiceConfig {}

extension ArtifactServiceConfigSerialization on ArtifactServiceConfig {
  Map<String, dynamic> toJson() {
    return _$ArtifactServiceConfigToJson(this);
  }
}

enum ArtifactServiceConfig$ { thresholdBytes }

class ArtifactServiceConfigPatch
    extends PatchBase<ArtifactServiceConfig, ArtifactServiceConfig$> {
  ArtifactServiceConfig applyTo(ArtifactServiceConfig entity) {
    return entity.patchWithArtifactServiceConfig(this);
  }

  ArtifactServiceConfigPatch withThresholdBytes(int? value) {
    patchMap[ArtifactServiceConfig$.thresholdBytes] = value;
    return this;
  }
}

/// Field descriptors for [ArtifactServiceConfig] query construction
abstract final class ArtifactServiceConfigFields {
  static const thresholdBytes = Field<ArtifactServiceConfig, int>(
    'thresholdBytes',
    _$thresholdBytes,
  );

  static int _$thresholdBytes(ArtifactServiceConfig e) {
    return e.thresholdBytes;
  }
}

extension ArtifactServiceConfigCompareE on ArtifactServiceConfig {
  Map<String, dynamic> compareToArtifactServiceConfig(
    ArtifactServiceConfig other,
  ) {
    final Map<String, dynamic> diff = {};

    if (thresholdBytes != other.thresholdBytes) {
      diff['thresholdBytes'] = () => other.thresholdBytes;
    }
    return diff;
  }
}
