import '../models/entity_marker.dart';
import '../models/has_parametrized_children.dart';
import '../models/has_plants.dart';
import '../models/parameter_model.dart';
import '../models/plant_model.dart';
import '../models/requirement_kind.dart';

/// One plant requirement that a pending parameter change would violate.
class PlantBreach {
  const PlantBreach({
    required this.plantName,
    required this.flowerpotName,
    required this.parameterName,
    required this.requestedValue,
    required this.unit,
    this.lower,
    this.upper,
  });

  final String plantName;
  final String flowerpotName;
  final String parameterName;
  final double requestedValue;
  final String unit;
  final double? lower;
  final double? upper;

  /// e.g. "Basil (Pot 1): Temperature 30.0 °C is outside 18.0–26.0 °C"
  String describe() {
    final range = '${lower?.toStringAsFixed(1) ?? '−∞'}–'
        '${upper?.toStringAsFixed(1) ?? '∞'} $unit';
    return '$plantName ($flowerpotName): $parameterName '
        '${requestedValue.toStringAsFixed(1)} $unit is outside $range';
  }
}

/// Computes which plants under [entity] would have a requirement broken by the
/// proposed [changed] parameter values. Pure/local — matches requirements to
/// parameters by name (case-insensitive) and tests the requested value against
/// each THRESHOLD requirement's range.
List<PlantBreach> checkParameterImpact(
    EntityMarker entity, List<Parameter> changed) {
  final breaches = <PlantBreach>[];
  final plants = _plantsUnder(entity);
  if (plants.isEmpty) return breaches;

  for (final param in changed) {
    final value = param.requestedValue;
    if (value == null) continue;
    for (final loc in plants) {
      for (final req in loc.plant.requirements) {
        if (req.kind != RequirementKind.threshold) continue;
        if (req.name.toLowerCase() != param.name.toLowerCase()) continue;
        if (value < req.lowerThreshold || value > req.upperThreshold) {
          breaches.add(PlantBreach(
            plantName: loc.plant.name,
            flowerpotName: loc.flowerpotName,
            parameterName: param.name,
            requestedValue: value,
            unit: req.unit,
            lower: req.lowerThreshold,
            upper: req.upperThreshold,
          ));
        }
      }
    }
  }
  return breaches;
}

class _PlantLocation {
  const _PlantLocation(this.flowerpotName, this.plant);
  final String flowerpotName;
  final Plant plant;
}

/// Collects every plant in the subtree rooted at [entity] together with the
/// name of the flowerpot it lives in. Flowerpots hold plants; zones/greenhouses
/// hold parametrized children, so we recurse down to the flowerpot level.
List<_PlantLocation> _plantsUnder(EntityMarker entity) {
  if (entity is HasPlants) {
    return entity.plantList
        .map((p) => _PlantLocation(entity.getName, p))
        .toList();
  }
  if (entity is HasParametrizedChildren) {
    return entity.parametrizedChildren
        .expand((child) => _plantsUnder(child))
        .toList();
  }
  return const [];
}
