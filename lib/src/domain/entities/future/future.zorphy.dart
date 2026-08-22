// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'future.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class Future {
  Future({required String this.id, dynamic this.value});

  factory Future.fromJson(Map<String, dynamic> json) => _$FutureFromJson(json);

  final String id;

  final dynamic value;

  Future copyWith({String? id, dynamic value}) {
    return Future(id: id ?? this.id, value: value ?? this.value);
  }

  Future copyWithFuture({String? id, dynamic value}) {
    return copyWith(id: id, value: value);
  }

  Future patchWithFuture([FuturePatch? patchInput]) {
    final _patcher = patchInput ?? FuturePatch();
    final _patchMap = _patcher.patchMap;
    return Future(
      id: _patchMap.containsKey(Future$.id)
          ? ((_patchMap[Future$.id] is Function)
                    ? _patchMap[Future$.id](this.id)
                    : (_patchMap[Future$.id] is Patch)
                    ? _patchMap[Future$.id].applyTo(this.id)
                    : _patchMap[Future$.id])
                as String
          : this.id,
      value: _patchMap.containsKey(Future$.value)
          ? ((_patchMap[Future$.value] is Function)
                    ? _patchMap[Future$.value](this.value)
                    : (_patchMap[Future$.value] is Patch)
                    ? _patchMap[Future$.value].applyTo(this.value)
                    : _patchMap[Future$.value])
                as dynamic
          : this.value,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Future && id == other.id && value == other.value;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.value);
  }

  @override
  String toString() {
    return 'Future(' + 'id: ${id}' + ', ' + 'value: ${value})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$FutureToJson(this);
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

extension FuturePropertyHelpers on Future {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }
}

extension FutureSerialization on Future {
  Map<String, dynamic> toJson() {
    return _$FutureToJson(this);
  }
}

enum Future$ { id, value }

class FuturePatch extends PatchBase<Future, Future$> {
  Future applyTo(Future entity) {
    return entity.patchWithFuture(this);
  }

  FuturePatch withId(String? value) {
    patchMap[Future$.id] = value;
    return this;
  }

  FuturePatch withValue(dynamic value) {
    patchMap[Future$.value] = value;
    return this;
  }
}

/// Field descriptors for [Future] query construction
abstract final class FutureFields {
  static const id = Field<Future, String>('id', _$id);

  static const value = Field<Future, dynamic>('value', _$value);

  static String _$id(Future e) {
    return e.id;
  }

  static dynamic _$value(Future e) {
    return e.value;
  }
}

extension FutureCompareE on Future {
  Map<String, dynamic> compareToFuture(Future other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (value != other.value) {
      diff['value'] = () => other.value;
    }
    return diff;
  }
}
