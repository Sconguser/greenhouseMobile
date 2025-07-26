import 'package:maker_greenhouse/models/parameter_model.dart';

import 'entity_marker.dart';

abstract interface class HasParameters implements EntityMarker {
  List<Parameter> get parameterList;
}
