import 'package:json_annotation/json_annotation.dart';

/// Mirrors the server `RequirementKind`. Only THRESHOLD is implemented today;
/// the enum exists so more kinds (e.g. watering) can be added later.
enum RequirementKind {
  @JsonValue('THRESHOLD')
  threshold,
}
