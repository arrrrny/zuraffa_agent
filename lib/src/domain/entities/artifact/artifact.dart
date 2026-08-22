/// Artifact entity — full artifact data with reference.
///
/// Stored by ArtifactService, fetched by ArtifactRef.id.
library;

import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'artifact.zorphy.dart';
part 'artifact.g.dart';

@Zorphy(generateJson: true, generateCompareTo: true)
abstract class $Artifact {
  String get refId;
  List<int> get data;
}