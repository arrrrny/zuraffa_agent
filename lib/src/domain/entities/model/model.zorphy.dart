// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'model.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class Model {
  Model({
    required String this.provider,
    required String this.modelId,
    required int this.contextWindow,
  });

  factory Model.fromJson(Map<String, dynamic> json) => _$ModelFromJson(json);

  final String provider;

  final String modelId;

  final int contextWindow;

  Model copyWith({String? provider, String? modelId, int? contextWindow}) {
    return Model(
      provider: provider ?? this.provider,
      modelId: modelId ?? this.modelId,
      contextWindow: contextWindow ?? this.contextWindow,
    );
  }

  Model copyWithModel({String? provider, String? modelId, int? contextWindow}) {
    return copyWith(
      provider: provider,
      modelId: modelId,
      contextWindow: contextWindow,
    );
  }

  Model patchWithModel([ModelPatch? patchInput]) {
    final _patcher = patchInput ?? ModelPatch();
    final _patchMap = _patcher.patchMap;
    return Model(
      provider: _patchMap.containsKey(Model$.provider)
          ? ((_patchMap[Model$.provider] is Function)
                    ? _patchMap[Model$.provider](this.provider)
                    : (_patchMap[Model$.provider] is Patch)
                    ? _patchMap[Model$.provider].applyTo(this.provider)
                    : _patchMap[Model$.provider])
                as String
          : this.provider,
      modelId: _patchMap.containsKey(Model$.modelId)
          ? ((_patchMap[Model$.modelId] is Function)
                    ? _patchMap[Model$.modelId](this.modelId)
                    : (_patchMap[Model$.modelId] is Patch)
                    ? _patchMap[Model$.modelId].applyTo(this.modelId)
                    : _patchMap[Model$.modelId])
                as String
          : this.modelId,
      contextWindow: _patchMap.containsKey(Model$.contextWindow)
          ? ((_patchMap[Model$.contextWindow] is Function)
                    ? _patchMap[Model$.contextWindow](this.contextWindow)
                    : (_patchMap[Model$.contextWindow] is Patch)
                    ? _patchMap[Model$.contextWindow].applyTo(
                        this.contextWindow,
                      )
                    : _patchMap[Model$.contextWindow])
                as int
          : this.contextWindow,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Model &&
        provider == other.provider &&
        modelId == other.modelId &&
        contextWindow == other.contextWindow;
  }

  @override
  int get hashCode {
    return Object.hash(this.provider, this.modelId, this.contextWindow);
  }

  @override
  String toString() {
    return 'Model(' +
        'provider: ${provider}' +
        ', ' +
        'modelId: ${modelId}' +
        ', ' +
        'contextWindow: ${contextWindow})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ModelToJson(this);
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

extension ModelPropertyHelpers on Model {
  bool get hasProvider {
    return this.provider.isNotEmpty;
  }

  bool get noProvider {
    return this.provider.isEmpty;
  }

  bool get hasModelId {
    return this.modelId.isNotEmpty;
  }

  bool get noModelId {
    return this.modelId.isEmpty;
  }
}

extension ModelSerialization on Model {
  Map<String, dynamic> toJson() {
    return _$ModelToJson(this);
  }
}

enum Model$ { provider, modelId, contextWindow }

class ModelPatch extends PatchBase<Model, Model$> {
  Model applyTo(Model entity) {
    return entity.patchWithModel(this);
  }

  ModelPatch withProvider(String? value) {
    patchMap[Model$.provider] = value;
    return this;
  }

  ModelPatch withModelId(String? value) {
    patchMap[Model$.modelId] = value;
    return this;
  }

  ModelPatch withContextWindow(int? value) {
    patchMap[Model$.contextWindow] = value;
    return this;
  }
}

/// Field descriptors for [Model] query construction
abstract final class ModelFields {
  static const provider = Field<Model, String>('provider', _$provider);

  static const modelId = Field<Model, String>('modelId', _$modelId);

  static const contextWindow = Field<Model, int>(
    'contextWindow',
    _$contextWindow,
  );

  static String _$provider(Model e) {
    return e.provider;
  }

  static String _$modelId(Model e) {
    return e.modelId;
  }

  static int _$contextWindow(Model e) {
    return e.contextWindow;
  }
}

extension ModelCompareE on Model {
  Map<String, dynamic> compareToModel(Model other) {
    final Map<String, dynamic> diff = {};

    if (provider != other.provider) {
      diff['provider'] = () => other.provider;
    }

    if (modelId != other.modelId) {
      diff['modelId'] = () => other.modelId;
    }

    if (contextWindow != other.contextWindow) {
      diff['contextWindow'] = () => other.contextWindow;
    }
    return diff;
  }
}
