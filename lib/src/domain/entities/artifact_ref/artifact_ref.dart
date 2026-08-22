/// Artifact Reference entity — points to stored artifact data.
///
/// Used for oversized tool results that are summarized with an artifactRef
/// instead of entering model context directly.
library;

import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'artifact_ref.zorphy.dart';
part 'artifact_ref.g.dart';

@Zorphy(generateJson: true, generateCompareTo: true)
abstract class $ArtifactRef {
  String get id;
  String get mimeType;
  int get sizeBytes;
  DateTime get createdAt;
}