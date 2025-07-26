import 'package:maker_greenhouse/models/entity_marker.dart';
import 'package:maker_greenhouse/models/requirement_model.dart';

abstract interface class HasRequirements implements EntityMarker {
  List<Requirement> get requirementList;
}
