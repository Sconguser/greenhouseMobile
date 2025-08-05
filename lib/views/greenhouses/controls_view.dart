import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maker_greenhouse/models/flowerpot_model.dart';
import 'package:maker_greenhouse/providers/greenhouse_notifier.dart';
import 'package:maker_greenhouse/shared/loading_indicator.dart';
import 'package:maker_greenhouse/views/greenhouses/widgets.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import '../../models/zone_model.dart';
import '../../models/entity_marker.dart';
import '../../models/greenhouse_model.dart';
import '../../generated/l10n.dart';
import '../../models/has_plants.dart';
import '../../shared/ui_constants.dart';

class ControlsView extends ConsumerWidget {
  const ControlsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    final greenhousesAsync = ref.watch(greenhouseNotifierProvider);
    return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: height * 0.9, maxWidth: width * 0.95),
          child: greenhousesAsync.when(
              data: (List<Greenhouse> data) => _buildListView(data, context),
              error: (Object error, StackTrace stackTrace) =>
                  _buildError(ref, error),
              loading: () => const LoadingIndicatorWidget()),
        ));
  }

  Widget _buildError(WidgetRef ref, Object error) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(S.current.error(error.toString())),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => ref.invalidate(greenhouseNotifierProvider),
          child: Text(S.current.retry),
        ),
      ],
    );
  }

  Future<dynamic> buildPlantListBottomSheet(
      BuildContext context, HasPlants entityWithPlants) {
    return showMaterialModalBottomSheet(
        elevation: 5,
        context: context,
        builder: (context) {
          return PlantModal(
            entityWithPlants: entityWithPlants,
          );
        });
  }

  void handleAddChild(
      EntityMarker parent, BuildContext context, WidgetRef ref) async {
    if (parent is Greenhouse) {
      buildAddZoneBottomSheet(context, ref, parent);
    } else if (parent is Zone) {
      buildAddFlowerpotBottomSheet(context, ref, parent);
    } else if (parent is HasPlants) {
      buildPlantListBottomSheet(context, parent);
    }
    // Continue for other entity types if needed...
  }

  Future<dynamic> buildAddFlowerpotBottomSheet(
      BuildContext context, WidgetRef ref, Zone zone) {
    return showMaterialModalBottomSheet(
        elevation: modalBottomSheetElevation,
        context: context,
        builder: (context) {
          return FlowerpotModal(
            appbarTitle: "Add new flowerpot",
            onAction: (name, parameters) async {
              if (zone.getId != null) {
                ref
                    .read(greenhouseNotifierProvider.notifier)
                    .addNewFlowerpotToZone(Flowerpot(name: name, parameters: parameters), zone.getId!);
              }
            },
            actionIcon: Icons.add,
            actionLabel: "Add new flowerpot",
            helpTitle: "Add new flowerpot help title placeholder",
            helpContent: "Add new flowerpot help content placeholder",
            parameters: [],
          );
        });
  }

  Future<dynamic> buildAddZoneBottomSheet(
      BuildContext context, WidgetRef ref, Greenhouse parent) {
    return showMaterialModalBottomSheet(
        elevation: modalBottomSheetElevation,
        context: context,
        builder: (context) {
          return ZoneModal(
            appbarTitle: "Add new zone",
            onAction: (name, parameters) async {
              if (parent.getId != null) {
                ref
                    .read(greenhouseNotifierProvider.notifier)
                    .addNewZoneToGreenhouse(Zone(name: name, parameters: parameters), parent.getId!);
              }
            },
            actionIcon: Icons.add,
            actionLabel: "Add new zone",
            helpTitle: "Add new zone help title placeholder",
            helpContent: "Add new zone help content placeholder",
            parameters: [],
          );
        });
  }

  ListView _buildListView(List<Greenhouse> greenhouses, BuildContext context) {
    greenhouses.sort((g1, g2) {
      if (g1.id != null && g2.id != null) {
        return g1.id!.compareTo(g2.id!);
      } else {
        return 0;
      }
    });
    double height = MediaQuery.of(context).size.height;
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: greenhouses.length + 1, // Add 1 for the button
      itemBuilder: (context, index) {
        if (index == greenhouses.length) {
          return AddNewGreenhouseButton(height: height);
        }

        final greenhouse = greenhouses[index];
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
          child: EntityTile(
            entity: greenhouse,
            onAddChild: handleAddChild,
            elevation: 0,
          ),
        );
      },
    );
  }
}
