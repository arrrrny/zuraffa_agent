// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#11.
//
// The zfa generator (arrrrny/zuraffa) currently emits a parameterless
// `list()` on the provider while the matching `ArtifactService` interface
// declares `list(NoParams params)`. The two generated artifacts are
// inconsistent and `lib` does not compile (analyzer code `invalid_override`).
//
// This file is the canonical hand-curated `ArtifactService` interface that
// ships in the consuming repo until the upstream zfa generator is fixed.
// When zfa does ship the consistent pair, this file may be deleted and
// regenerated; until then it is the source of truth.
//
// Rule: every parameterless service method declares an explicit `NoParams`
// parameter so the implementing provider can `@override` it without ambiguity.

import 'package:zuraffa/zuraffa.dart';

import '../entities/artifact_ref/artifact_ref.dart';

/// Surface contract for the artifact data layer.
///
/// Both methods are parameterless at the domain level (no caller-supplied
/// filter or sort), so they declare the `NoParams` marker type to keep the
/// provider/service signatures aligned.
abstract class ArtifactService {
  /// Returns every persisted artifact reference.
  Future<List<ArtifactRef>> list(NoParams params);

  /// Per-call size threshold in bytes beyond which an oversized tool result
  /// is summarized + stored rather than streamed directly into model context.
  int thresholdBytes(NoParams params);
}
