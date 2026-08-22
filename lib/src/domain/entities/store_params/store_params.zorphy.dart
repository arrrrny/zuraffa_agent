// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'store_params.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class StoreParams {
  StoreParams({required List<int> this.data, required String this.mimeType});

  factory StoreParams.fromJson(Map<String, dynamic> json) =>
      _$StoreParamsFromJson(json);

  final List<int> data;

  final String mimeType;

  StoreParams copyWith({List<int>? data, String? mimeType}) {
    return StoreParams(
      data: data ?? this.data,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  StoreParams copyWithStoreParams({List<int>? data, String? mimeType}) {
    return copyWith(data: data, mimeType: mimeType);
  }

  StoreParams patchWithStoreParams([StoreParamsPatch? patchInput]) {
    final _patcher = patchInput ?? StoreParamsPatch();
    final _patchMap = _patcher.patchMap;
    return StoreParams(
      data: _patchMap.containsKey(StoreParams$.data)
          ? ((_patchMap[StoreParams$.data] is Function)
                    ? _patchMap[StoreParams$.data](this.data)
                    : (_patchMap[StoreParams$.data] is Patch)
                    ? _patchMap[StoreParams$.data].applyTo(this.data)
                    : _patchMap[StoreParams$.data])
                as List<int>
          : this.data,
      mimeType: _patchMap.containsKey(StoreParams$.mimeType)
          ? ((_patchMap[StoreParams$.mimeType] is Function)
                    ? _patchMap[StoreParams$.mimeType](this.mimeType)
                    : (_patchMap[StoreParams$.mimeType] is Patch)
                    ? _patchMap[StoreParams$.mimeType].applyTo(this.mimeType)
                    : _patchMap[StoreParams$.mimeType])
                as String
          : this.mimeType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StoreParams &&
        data == other.data &&
        mimeType == other.mimeType;
  }

  @override
  int get hashCode {
    return Object.hash(this.data, this.mimeType);
  }

  @override
  String toString() {
    return 'StoreParams(' + 'data: ${data}' + ', ' + 'mimeType: ${mimeType})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$StoreParamsToJson(this);
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

extension StoreParamsPropertyHelpers on StoreParams {
  bool get hasData {
    return this.data.isNotEmpty;
  }

  bool get noData {
    return this.data.isEmpty;
  }

  bool get hasMimeType {
    return this.mimeType.isNotEmpty;
  }

  bool get noMimeType {
    return this.mimeType.isEmpty;
  }
}

extension StoreParamsSerialization on StoreParams {
  Map<String, dynamic> toJson() {
    return _$StoreParamsToJson(this);
  }
}

enum StoreParams$ { data, mimeType }

class StoreParamsPatch extends PatchBase<StoreParams, StoreParams$> {
  StoreParams applyTo(StoreParams entity) {
    return entity.patchWithStoreParams(this);
  }

  StoreParamsPatch withData(List<int>? value) {
    patchMap[StoreParams$.data] = value;
    return this;
  }

  StoreParamsPatch withMimeType(String? value) {
    patchMap[StoreParams$.mimeType] = value;
    return this;
  }
}

/// Field descriptors for [StoreParams] query construction
abstract final class StoreParamsFields {
  static const data = Field<StoreParams, List<int>>('data', _$data);

  static const mimeType = Field<StoreParams, String>('mimeType', _$mimeType);

  static List<int> _$data(StoreParams e) {
    return e.data;
  }

  static String _$mimeType(StoreParams e) {
    return e.mimeType;
  }
}

extension StoreParamsCompareE on StoreParams {
  Map<String, dynamic> compareToStoreParams(StoreParams other) {
    final Map<String, dynamic> diff = {};

    if (data != other.data) {
      diff['data'] = () => other.data;
    }

    if (mimeType != other.mimeType) {
      diff['mimeType'] = () => other.mimeType;
    }
    return diff;
  }
}
