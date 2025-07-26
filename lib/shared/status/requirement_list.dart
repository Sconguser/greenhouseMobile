import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/requirement_model.dart';

class RequirementList extends ConsumerWidget {
  const RequirementList({super.key, required this.requirements});

  final List<Requirement> requirements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...requirements.map((requirement) => Text(
                "${requirement.name}: ${requirement.lowerThreshold} ${requirement.upperThreshold} ${requirement.unit}"))
          ],
        ),
      ],
    );
  }
}
