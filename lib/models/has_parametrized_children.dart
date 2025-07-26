import 'package:maker_greenhouse/models/has_parameters.dart';

import 'entity_marker.dart';

abstract interface class HasParametrizedChildren implements EntityMarker{
  List<HasParameters> get parametrizedChildren;
}