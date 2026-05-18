import 'package:json_annotation/json_annotation.dart';

enum ParameterType {
  @JsonValue('Toggle')
  TOGGLE,
  @JsonValue('Value')
  VALUE
}
