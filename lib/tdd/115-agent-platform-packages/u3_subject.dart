// GENERATED STUB — hand-stepped (spec 115 U3): the real validator.
// ignore_for_file: non_constant_identifier_names
library;

import 'package:zuraffa_agent/zuraffa_agent.dart';

/// Subject for behavior U3 — declared contract: `validate(key) -> void`.
void subject_u3(String? key) {
  if (key == null) {
    throw ArgumentError.value(null, 'key', 'must be non-empty');
  }
  SecureStore.validate(key);
}
