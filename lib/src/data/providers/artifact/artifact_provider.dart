// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#11.
//
// Concrete provider for the artifact data layer. Returns the persisted
// artifact references and the per-call oversized-result threshold (in bytes,
// beyond which a tool result is summarized + stored rather than streamed into
// model context) as constructed/in-memory defaults (spec 052).
//
// The header intentionally does NOT say `// GENERATED - DO NOT EDIT` — this
// file was written by hand and is the canonical source until zfa ships a
// consistent ArtifactProvider/ArtifactService pair.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/artifact_ref/artifact_ref.dart';
import '../../../domain/services/artifact_service.dart';

/// Provider for the artifact data layer.
///
/// Returns constructed/in-memory defaults so the engine stays free of platform
/// I/O. Real persistence is wired by the consuming application.
class ArtifactProvider with Loggable, FailureHandler implements ArtifactService {
  static const int _kDefaultThresholdBytes = 65536;

  final List<ArtifactRef> _refs;
  final int _thresholdBytes;

  ArtifactProvider([List<ArtifactRef>? refs, int? thresholdBytes])
      : _refs = refs ??
            [
              ArtifactRef(
                kind: 'file',
                id: 'artifact-0',
                uri: 'file:///tmp/artifact-0',
              ),
            ],
        _thresholdBytes = thresholdBytes ?? _kDefaultThresholdBytes;

  @override
  Future<List<ArtifactRef>> list(NoParams params) async => _refs;

  @override
  int thresholdBytes(NoParams params) => _thresholdBytes;
}
