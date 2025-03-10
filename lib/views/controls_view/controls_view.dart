import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maker_greenhouse/providers/plant_list_controller_provider.dart';

import '../../models/plant_model.dart';
import 'widgets.dart';

class ControlsView extends ConsumerWidget {
  const ControlsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    List<Plant> plants = ref.watch(plantListNotifierProvider);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: height * 0.9, maxWidth: width * 0.8),
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: plants.length + 1, // Add 1 for the button
            itemBuilder: (context, index) {
              // If the index is the last one, return the button
              if (index == plants.length) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                        context, '/add'); // Redirect to Add Plant View
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: const Icon(Icons.add),
                  ),
                );
              }

              // For all other indices, return the plant tiles
              final plant = plants[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: PlantTile(
                  plant: plant,
                ),
              );
            },
          )),
    );
  }
}
