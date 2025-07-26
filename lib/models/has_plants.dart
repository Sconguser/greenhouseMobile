import 'package:maker_greenhouse/models/entity_marker.dart';
import 'package:maker_greenhouse/models/plant_model.dart';

abstract interface class HasPlants implements EntityMarker{
  List<Plant> get plantList;
}
