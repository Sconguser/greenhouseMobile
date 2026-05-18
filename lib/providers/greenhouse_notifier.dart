import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/flowerpot_model.dart';
import '../models/greenhouse_model.dart';
import '../models/parameter_model.dart';
import '../models/zone_model.dart';
import 'http_conf.dart';
import 'http_service.dart';

part 'greenhouse_notifier.g.dart';

@riverpod
class GreenhouseNotifier extends _$GreenhouseNotifier {
  @override
  Future<List<Greenhouse>> build() async {
    final greenhouses = await _fetchGreenhouses();
    if (greenhouses.any(_hasPendingSync)) {
      final timer = Timer(const Duration(seconds: 5), () => silentRefresh());
      ref.onDispose(timer.cancel);
    }
    return greenhouses;
  }

  static bool _hasPendingSync(Greenhouse gh) =>
      gh.deviceConfigSynced == false ||
      gh.mappingConfigSynced == false ||
      gh.modelSynced == false;

  // Fetches without touching state — used by both initial load and silent refresh.
  Future<List<Greenhouse>> _fetchGreenhouses() async {
    final response = await ref
        .read(httpServiceProvider)
        .request(method: HttpMethod.get, endpoint: '/greenhouse/');
    final utf8Body = utf8.decode(response.bodyBytes);
    final List<dynamic> decoded = jsonDecode(utf8Body);
    return decoded
        .map((e) => Greenhouse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Updates state data→data with no loading flash; re-schedules itself if
  // any greenhouse still has a pending sync flag.
  Future<void> silentRefresh() async {
    try {
      final updated = await _fetchGreenhouses();
      state = AsyncValue.data(updated);
      if (updated.any(_hasPendingSync)) {
        final timer = Timer(const Duration(seconds: 5), () => silentRefresh());
        ref.onDispose(timer.cancel);
      }
    } catch (_) {
      // Don't break the existing view on a background refresh failure.
    }
  }

  Future<List<Greenhouse>> _loadGreenhouses() async {
    state = AsyncValue.loading();
    try {
      return await _fetchGreenhouses();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ─── Greenhouse CRUD ────────────────────────────────────────────────────────

  Future<void> addNewGreenhouse(Greenhouse greenhouse) async {
    state = AsyncValue.loading();
    try {
      final response = await ref.read(httpServiceProvider).request(
            method: HttpMethod.post,
            endpoint: '/greenhouse/add',
            body: greenhouse.toJson(),
          );
      if (response.statusCode == 200) {
        state = AsyncValue.data(await _loadGreenhouses());
      } else {
        throw Exception('Failed to add greenhouse');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> editGreenhouse(Greenhouse greenhouse, int greenhouseId) async {
    List<Greenhouse>? previous = _currentList;
    state = AsyncValue.loading();
    try {
      final response = await ref.read(httpServiceProvider).request(
            method: HttpMethod.patch,
            endpoint: '/greenhouse/$greenhouseId',
            body: greenhouse.toJson(),
          );
      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final edited =
            Greenhouse.fromJson(jsonDecode(utf8Body) as Map<String, dynamic>);
        if (previous != null) {
          state = AsyncValue.data([
            ...previous.where((g) => g.id != greenhouseId),
            edited,
          ]);
        } else {
          state = AsyncValue.data(await _loadGreenhouses());
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteGreenhouse(int greenhouseId) async {
    state = AsyncValue.loading();
    try {
      await ref.read(httpServiceProvider).request(
            method: HttpMethod.delete,
            endpoint: '/greenhouse/$greenhouseId',
          );
      state = AsyncValue.data(await _loadGreenhouses());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> pushModelToGreenhouse(int greenhouseId) async {
    await ref.read(httpServiceProvider).request(
          method: HttpMethod.post,
          endpoint: '/greenhouse/$greenhouseId/push',
        );
    await silentRefresh();
  }

  // ─── Zone CRUD ───────────────────────────────────────────────────────────────

  Future<void> addNewZoneToGreenhouse(Zone zone, int greenhouseId) async {
    state = AsyncValue.loading();
    try {
      final zoneResponse = await ref.read(httpServiceProvider).request(
            method: HttpMethod.post,
            endpoint: '/greenhouse/$greenhouseId/addZone',
            body: {'name': zone.name},
          );
      if (zoneResponse.statusCode != 200) {
        throw Exception('Failed to create zone');
      }
      final newZone = Zone.fromJson(
          jsonDecode(utf8.decode(zoneResponse.bodyBytes)) as Map<String, dynamic>);

      // Add each parameter separately after the zone is created
      if (newZone.id != null) {
        for (final param in zone.parameters) {
          await ref.read(httpServiceProvider).request(
                method: HttpMethod.post,
                endpoint: '/zone/${newZone.id}/addParameter',
                body: param.toJson(),
              );
        }
      }
      state = AsyncValue.data(await _loadGreenhouses());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteZone(int greenhouseId, int zoneId) async {
    state = AsyncValue.loading();
    try {
      await ref.read(httpServiceProvider).request(
            method: HttpMethod.delete,
            endpoint: '/greenhouse/$greenhouseId/deleteZone/$zoneId',
          );
      state = AsyncValue.data(await _loadGreenhouses());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> editZone(String name, int zoneId) async {
    state = AsyncValue.loading();
    try {
      await ref.read(httpServiceProvider).request(
            method: HttpMethod.patch,
            endpoint: '/zone/$zoneId',
            body: {'name': name},
          );
      state = AsyncValue.data(await _loadGreenhouses());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ─── Flowerpot CRUD ──────────────────────────────────────────────────────────

  Future<void> addNewFlowerpotToZone(Flowerpot flowerpot, int zoneId) async {
    state = AsyncValue.loading();
    try {
      final potResponse = await ref.read(httpServiceProvider).request(
            method: HttpMethod.post,
            endpoint: '/zone/$zoneId/addFlowerpot',
            body: {'name': flowerpot.name},
          );
      if (potResponse.statusCode != 200) {
        throw Exception('Failed to create flowerpot');
      }
      final newPot = Flowerpot.fromJson(
          jsonDecode(utf8.decode(potResponse.bodyBytes)) as Map<String, dynamic>);

      // Add each parameter separately after the flowerpot is created
      if (newPot.id != null) {
        for (final param in flowerpot.parameters) {
          await ref.read(httpServiceProvider).request(
                method: HttpMethod.post,
                endpoint: '/flowerpot/${newPot.id}/addParameter',
                body: param.toJson(),
              );
        }
      }
      state = AsyncValue.data(await _loadGreenhouses());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> editFlowerpot(String name, int flowerpotId) async {
    state = AsyncValue.loading();
    try {
      await ref.read(httpServiceProvider).request(
            method: HttpMethod.patch,
            endpoint: '/flowerpot/$flowerpotId',
            body: {'name': name},
          );
      state = AsyncValue.data(await _loadGreenhouses());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteFlowerpot(int zoneId, int flowerpotId) async {
    state = AsyncValue.loading();
    try {
      await ref.read(httpServiceProvider).request(
            method: HttpMethod.delete,
            endpoint: '/zone/$zoneId/deleteFlowerpot/$flowerpotId',
          );
      state = AsyncValue.data(await _loadGreenhouses());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ─── Plant ───────────────────────────────────────────────────────────────────

  Future<void> addNewPlantToFlowerpot(int plantId, int flowerpotId) async {
    state = AsyncValue.loading();
    try {
      final response = await ref.read(httpServiceProvider).request(
            method: HttpMethod.put,
            endpoint: '/flowerpot/$flowerpotId/addPlant/$plantId',
          );
      if (response.statusCode == 200) {
        state = AsyncValue.data(await _loadGreenhouses());
      } else {
        throw Exception('Failed to add plant to flowerpot');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> removePlantFromFlowerpot(int flowerpotId, int plantId) async {
    state = AsyncValue.loading();
    try {
      await ref.read(httpServiceProvider).request(
            method: HttpMethod.delete,
            endpoint: '/flowerpot/$flowerpotId/deletePlant/$plantId',
          );
      state = AsyncValue.data(await _loadGreenhouses());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ─── Parameters ──────────────────────────────────────────────────────────────

  Future<void> updateParameters(List<Parameter> parameters) async {
    state = AsyncValue.loading();
    try {
      final response = await ref.read(httpServiceProvider).request(
            method: HttpMethod.patch,
            endpoint: '/parameter/updateParameters',
            body: parameters.map((p) => p.toJson()).toList(),
          );
      if (response.statusCode == 200) {
        state = AsyncValue.data(await _loadGreenhouses());
      } else {
        throw Exception('Failed to update parameters');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> addParameterToGreenhouse(
      Parameter parameter, int greenhouseId) async {
    state = AsyncValue.loading();
    try {
      await ref.read(httpServiceProvider).request(
            method: HttpMethod.post,
            endpoint: '/greenhouse/$greenhouseId/addParameter',
            body: parameter.toJson(),
          );
      state = AsyncValue.data(await _loadGreenhouses());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> addParameterToZone(Parameter parameter, int zoneId) async {
    state = AsyncValue.loading();
    try {
      await ref.read(httpServiceProvider).request(
            method: HttpMethod.post,
            endpoint: '/zone/$zoneId/addParameter',
            body: parameter.toJson(),
          );
      state = AsyncValue.data(await _loadGreenhouses());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> addParameterToFlowerpot(
      Parameter parameter, int flowerpotId) async {
    state = AsyncValue.loading();
    try {
      await ref.read(httpServiceProvider).request(
            method: HttpMethod.post,
            endpoint: '/flowerpot/$flowerpotId/addParameter',
            body: parameter.toJson(),
          );
      state = AsyncValue.data(await _loadGreenhouses());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteParameter(int parameterId) async {
    state = AsyncValue.loading();
    try {
      await ref.read(httpServiceProvider).request(
            method: HttpMethod.delete,
            endpoint: '/parameter/$parameterId',
          );
      state = AsyncValue.data(await _loadGreenhouses());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  List<Greenhouse>? get _currentList =>
      state is AsyncData<List<Greenhouse>>
          ? (state as AsyncData<List<Greenhouse>>).value
          : null;

  // Finds the zone that contains a given flowerpot by searching the loaded state.
  int? findZoneIdForFlowerpot(int flowerpotId) {
    final greenhouses = _currentList;
    if (greenhouses == null) return null;
    for (final gh in greenhouses) {
      for (final zone in gh.zones) {
        if (zone.flowerpots.any((fp) => fp.id == flowerpotId)) {
          return zone.id;
        }
      }
    }
    return null;
  }

  // Finds the greenhouse that contains a given zone.
  int? findGreenhouseIdForZone(int zoneId) {
    final greenhouses = _currentList;
    if (greenhouses == null) return null;
    for (final gh in greenhouses) {
      if (gh.zones.any((z) => z.id == zoneId)) return gh.id;
    }
    return null;
  }
}