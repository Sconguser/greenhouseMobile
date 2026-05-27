import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maker_greenhouse/models/flowerpot_model.dart';
import 'package:maker_greenhouse/models/has_plants.dart';
import 'package:maker_greenhouse/models/plant_model.dart';
import 'package:maker_greenhouse/models/zone_model.dart';
import 'package:maker_greenhouse/providers/greenhouse_notifier.dart';
import 'package:maker_greenhouse/shared/loading_indicator.dart';
import 'package:maker_greenhouse/views/config/device_config_view.dart';
import 'package:maker_greenhouse/views/config/mapping_config_view.dart';
import 'package:maker_greenhouse/views/greenhouses/widgets.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import '../../generated/l10n.dart';
import '../../models/entity_marker.dart';
import '../../models/greenhouse_model.dart';
import '../../models/parameter_model.dart';
import '../../shared/ui_constants.dart';

class ControlsView extends ConsumerWidget {
  const ControlsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final greenhousesAsync = ref.watch(greenhouseNotifierProvider);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: height * 0.9, maxWidth: width * 0.95),
        child: greenhousesAsync.when(
          skipLoadingOnReload: true,
          data: (data) => _buildListView(data, context, ref),
          error: (error, _) => _buildError(ref, error),
          loading: () => const LoadingIndicatorWidget(),
        ),
      ),
    );
  }

  // ─── Error state ────────────────────────────────────────────────────────────

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

  // ─── List ────────────────────────────────────────────────────────────────────

  Widget _buildListView(
      List<Greenhouse> greenhouses, BuildContext context, WidgetRef ref) {
    greenhouses.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    final height = MediaQuery.of(context).size.height;
    return Column(
      children: [
        // ── Refresh row ─────────────────────────────────────────────────────
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(greenhouseNotifierProvider.notifier).silentRefresh(),
          ),
        ),
        // ── Greenhouse list ──────────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(greenhouseNotifierProvider.notifier).silentRefresh(),
            child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
      itemCount: greenhouses.isEmpty ? 2 : greenhouses.length + 1,
      itemBuilder: (context, index) {
        if (greenhouses.isEmpty && index == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.home_work_outlined,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(S.of(context).noGreenhousesYet,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(S.of(context).noGreenhousesSubtitle,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          );
        }
        if (index >= greenhouses.length) {
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
                color: Colors.grey.withValues(alpha: 0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: EntityTile(
            entity: greenhouse,
            elevation: 0,
            pendingChanges: _buildPendingChanges(greenhouse, context),
            onAddChild: (parent, ctx, r) => _handleAddChild(parent, ctx, r),
            onEdit: (entity, ctx, r) => _handleEdit(entity, ctx, r),
            onDelete: (entity, ctx, r) => _handleDelete(entity, ctx, r),
            onPushToBoard: (gh, ctx, r) => _handlePush(gh, ctx, r),
            onConfigureDevices: (gh, ctx, _) =>
                _openDeviceConfig(gh, context),
            onConfigureMapping: (gh, ctx, _) =>
                _openMappingConfig(gh, context),
            onAddParameter: (entity, param) =>
                _handleAddParameter(entity, param, ref),
            onDeleteParameter: (param) => _handleDeleteParameter(param, ref),
            onRemovePlant: (plant, parent) =>
                _handleRemovePlant(plant, parent, ref),
          ),
        );
      },
      ),        // ListView.builder
          ),    // RefreshIndicator
        ),      // Expanded
      ],
    );          // Column
  }

  // ─── Add child ───────────────────────────────────────────────────────────────

  void _handleAddChild(
      EntityMarker parent, BuildContext context, WidgetRef ref) {
    if (parent is Greenhouse) {
      _showAddZoneSheet(context, ref, parent);
    } else if (parent is Zone) {
      _showAddFlowerpotSheet(context, ref, parent);
    } else if (parent is HasPlants) {
      showMaterialModalBottomSheet(
        elevation: 5,
        context: context,
        builder: (_) => PlantModal(entityWithPlants: parent),
      );
    }
  }

  void _showAddZoneSheet(
      BuildContext context, WidgetRef ref, Greenhouse parent) {
    final s = S.of(context);
    showMaterialModalBottomSheet(
      elevation: modalBottomSheetElevation,
      context: context,
      builder: (_) => ZoneModal(
        appbarTitle: s.addZoneModalTitle,
        onAction: (name, params) {
          if (parent.getId != null) {
            ref
                .read(greenhouseNotifierProvider.notifier)
                .addNewZoneToGreenhouse(
                    Zone(name: name, parameters: params), parent.getId!);
          }
        },
        actionIcon: Icons.add,
        actionLabel: s.addZone,
        helpTitle: s.addZoneHelpTitle,
        helpContent: s.addZoneHelpContent,
        parameters: const [],
      ),
    );
  }

  void _showAddFlowerpotSheet(
      BuildContext context, WidgetRef ref, Zone zone) {
    final s = S.of(context);
    showMaterialModalBottomSheet(
      elevation: modalBottomSheetElevation,
      context: context,
      builder: (_) => FlowerpotModal(
        appbarTitle: s.addFlowerpotModalTitle,
        onAction: (name, params) {
          if (zone.getId != null) {
            ref
                .read(greenhouseNotifierProvider.notifier)
                .addNewFlowerpotToZone(
                    Flowerpot(name: name, parameters: params), zone.getId!);
          }
        },
        actionIcon: Icons.add,
        actionLabel: s.addFlowerpot,
        helpTitle: s.addFlowerpotHelpTitle,
        helpContent: s.addFlowerpotHelpContent,
        parameters: const [],
      ),
    );
  }

  // ─── Edit ────────────────────────────────────────────────────────────────────

  void _handleEdit(
      EntityMarker entity, BuildContext context, WidgetRef ref) {
    if (entity is Greenhouse) {
      final s = S.of(context);
      showMaterialModalBottomSheet(
        elevation: modalBottomSheetElevation,
        context: context,
        builder: (_) => GreenhouseModal(
          appbarTitle: s.editGreenhouseModalTitle,
          initialName: entity.name,
          initialLocation: entity.location,
          initialIpAddress: entity.ipAddress,
          parameters: entity.parameters,
          onAction: (name, location, ip, params) {
            ref.read(greenhouseNotifierProvider.notifier).editGreenhouse(
                  Greenhouse(
                      name: name,
                      location: location,
                      ipAddress: ip,
                      parameters: params),
                  entity.id!,
                );
          },
          actionIcon: Icons.save,
          actionLabel: s.save,
          helpTitle: s.editGreenhouseHelpTitle,
          helpContent: s.editGreenhouseHelpContent,
        ),
      );
    } else if (entity is Zone && entity.id != null) {
      showMaterialModalBottomSheet(
        elevation: modalBottomSheetElevation,
        context: context,
        builder: (_) => RenameZoneModal(zone: entity),
      );
    } else if (entity is Flowerpot && entity.id != null) {
      showMaterialModalBottomSheet(
        elevation: modalBottomSheetElevation,
        context: context,
        builder: (_) => RenameFlowerpotModal(flowerpot: entity),
      );
    }
  }

  // ─── Delete ──────────────────────────────────────────────────────────────────

  void _handleDelete(
      EntityMarker entity, BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(s.deleteConfirmTitle(entity.getName)),
        content: Text(s.deleteConfirmContent(entity.getName)),
        actions: [
          TextButton(
            child: Text(s.cancel),
            onPressed: () => Navigator.of(dialogCtx).pop(),
          ),
          TextButton(
            child: Text(s.delete, style: const TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _performDelete(entity, ref, context);
            },
          ),
        ],
      ),
    );
  }

  void _performDelete(
      EntityMarker entity, WidgetRef ref, BuildContext context) {
    final notifier = ref.read(greenhouseNotifierProvider.notifier);
    if (entity is Greenhouse && entity.id != null) {
      notifier.deleteGreenhouse(entity.id!);
    } else if (entity is Zone && entity.id != null) {
      final ghId = notifier.findGreenhouseIdForZone(entity.id!);
      if (ghId != null) notifier.deleteZone(ghId, entity.id!);
    } else if (entity is Flowerpot && entity.id != null) {
      final zoneId = notifier.findZoneIdForFlowerpot(entity.id!);
      if (zoneId != null) notifier.deleteFlowerpot(zoneId, entity.id!);
    }
  }

  // ─── Push to board ───────────────────────────────────────────────────────────

  void _handlePush(
      Greenhouse greenhouse, BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(s.pushToBoardTitle),
        content: Text(s.pushToBoardContent(greenhouse.ipAddress)),
        actions: [
          TextButton(
            child: Text(s.cancel),
            onPressed: () => Navigator.of(dialogCtx).pop(),
          ),
          TextButton(
            child: Text(s.push),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              if (greenhouse.id != null) {
                ref
                    .read(greenhouseNotifierProvider.notifier)
                    .pushModelToGreenhouse(greenhouse.id!);
              }
            },
          ),
        ],
      ),
    );
  }

  // ─── Config screens ──────────────────────────────────────────────────────────

  void _openDeviceConfig(Greenhouse greenhouse, BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DeviceConfigView(greenhouse: greenhouse),
    ));
  }

  void _openMappingConfig(Greenhouse greenhouse, BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MappingConfigView(greenhouse: greenhouse),
    ));
  }

  // ─── Parameter management ────────────────────────────────────────────────────

  Future<void> _handleAddParameter(
      EntityMarker entity, Parameter param, WidgetRef ref) async {
    final notifier = ref.read(greenhouseNotifierProvider.notifier);
    final id = entity.getId;
    if (id == null) return;
    if (entity is Greenhouse) {
      await notifier.addParameterToGreenhouse(param, id);
    } else if (entity is Zone) {
      await notifier.addParameterToZone(param, id);
    } else if (entity is Flowerpot) {
      await notifier.addParameterToFlowerpot(param, id);
    }
  }

  Future<void> _handleDeleteParameter(
      Parameter param, WidgetRef ref) async {
    if (param.id == null) return;
    await ref
        .read(greenhouseNotifierProvider.notifier)
        .deleteParameter(param.id!);
  }

  // ─── Plant management ────────────────────────────────────────────────────────

  void _handleRemovePlant(
      Plant plant, HasPlants parent, WidgetRef ref) {
    if (plant.getId == null || parent.getId == null) return;
    ref
        .read(greenhouseNotifierProvider.notifier)
        .removePlantFromFlowerpot(parent.getId!, plant.getId!);
  }

  // ─── Pending changes ─────────────────────────────────────────────────────────

  static List<String> _buildPendingChanges(Greenhouse gh, BuildContext context) {
    final s = S.of(context);
    final lastPushed = gh.lastPushed;
    final changes = <String>[];

    bool isNew(DateTime? createdAt) {
      if (createdAt == null) return false;
      if (lastPushed == null) return true;
      return createdAt.isAfter(lastPushed);
    }

    bool isValueChanged(Parameter p) {
      final updatedAt = p.updatedAt;
      if (updatedAt == null) return false;
      if (isNew(p.createdAt)) return false;
      if (lastPushed == null) return true;
      return updatedAt.isAfter(lastPushed);
    }

    if (gh.modelDirtyAt != null &&
        (lastPushed == null || gh.modelDirtyAt!.isAfter(lastPushed))) {
      changes.add(s.pendingChangesParameterDeleted);
    }

    for (final p in gh.parameters) {
      if (isNew(p.createdAt)) {
        changes.add(s.pendingChangesParameterAddedToGreenhouse(p.name));
      } else if (isValueChanged(p)) {
        changes.add(s.pendingChangesParameterValueChangedInGreenhouse(p.name));
      }
    }
    for (final z in gh.zones) {
      if (isNew(z.createdAt)) changes.add(s.pendingChangesZoneAdded(z.name));
      for (final p in z.parameters) {
        if (isNew(p.createdAt)) {
          changes.add(s.pendingChangesParameterAddedToZone(p.name, z.name));
        } else if (isValueChanged(p)) {
          changes.add(s.pendingChangesParameterValueChangedInZone(p.name, z.name));
        }
      }
      for (final fp in z.flowerpots) {
        if (isNew(fp.createdAt)) {
          changes.add(s.pendingChangesFlowerpotAdded(fp.name));
        }
        for (final p in fp.parameters) {
          if (isNew(p.createdAt)) {
            changes.add(s.pendingChangesParameterAddedToFlowerpot(p.name, fp.name));
          } else if (isValueChanged(p)) {
            changes.add(s.pendingChangesParameterValueChangedInFlowerpot(p.name, fp.name));
          }
        }
      }
    }
    return changes;
  }
}