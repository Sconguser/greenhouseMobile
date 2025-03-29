import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/greenhouse_model.dart';

class GreenhouseDetailsView extends ConsumerWidget {
  const GreenhouseDetailsView({super.key, required this.greenhouse});

  final Greenhouse greenhouse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container();
  }
}
