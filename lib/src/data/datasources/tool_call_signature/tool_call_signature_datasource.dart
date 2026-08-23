// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/tool_call_signature/tool_call_signature.dart';

abstract class ToolCallSignatureDataSource with Loggable, FailureHandler {
  Future<ToolCallSignature> get(QueryParams<ToolCallSignature> params);
  Future<ToolCallSignature> update(
    UpdateParams<String, ToolCallSignaturePatch> params,
  );
}

// END GENERATED
