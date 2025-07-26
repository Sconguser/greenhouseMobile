import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/parameter_model.dart';

class ParameterList extends ConsumerWidget {
  const ParameterList({super.key, required this.parameters});

  final List<Parameter> parameters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...parameters.map((parameter) => Text(
                "${parameter.name}: ${parameter.currentValue} ${parameter.unit}"))
          ],
        ),
      ],
    );
  }
}
