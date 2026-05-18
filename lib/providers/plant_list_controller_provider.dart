import 'dart:convert';

import 'package:maker_greenhouse/providers/http_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/plant_model.dart';
import '../models/requirement_model.dart';
import 'http_conf.dart';

part 'plant_list_controller_provider.g.dart';

@riverpod
class PlantListNotifier extends _$PlantListNotifier {
  @override
  Future<List<Plant>> build() async {
    return _loadPlants();
  }

  Future<List<Plant>> _loadPlants() async {
    state = AsyncValue.loading();
    try {
      final response = await ref
          .read(httpServiceProvider)
          .request(method: HttpMethod.get, endpoint: '/plants/');
      final utf8Body = utf8.decode(response.bodyBytes);
      final List<dynamic> decoded = jsonDecode(utf8Body);
      return decoded
          .map((e) => Plant.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> addPlant(Plant newPlant) async {
    try {
      final response = await ref.read(httpServiceProvider).request(
            method: HttpMethod.post,
            endpoint: '/plants/addPlant',
            body: newPlant.toJson(),
          );
      if (response.statusCode == 200) {
        if (state is AsyncData<List<Plant>>) {
          final current = (state as AsyncData<List<Plant>>).value;
          state = AsyncValue.data([...current, newPlant]);
        }
      } else {
        throw Exception('Failed to add plant');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updatePlant(Plant plant, int plantId) async {
    state = AsyncValue.loading();
    try {
      final response = await ref.read(httpServiceProvider).request(
            method: HttpMethod.patch,
            endpoint: '/plants/$plantId',
            body: plant.toJson(),
          );
      if (response.statusCode == 200) {
        state = AsyncValue.data(await _loadPlants());
      } else {
        throw Exception('Failed to update plant');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deletePlant(int plantId) async {
    state = AsyncValue.loading();
    try {
      await ref.read(httpServiceProvider).request(
            method: HttpMethod.delete,
            endpoint: '/plants/$plantId',
          );
      state = AsyncValue.data(await _loadPlants());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> addRequirement(Requirement requirement, int plantId) async {
    state = AsyncValue.loading();
    try {
      await ref.read(httpServiceProvider).request(
            method: HttpMethod.post,
            endpoint: '/plants/$plantId/addRequirement',
            body: requirement.toJson(),
          );
      state = AsyncValue.data(await _loadPlants());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteRequirement(int requirementId) async {
    state = AsyncValue.loading();
    try {
      await ref.read(httpServiceProvider).request(
            method: HttpMethod.delete,
            endpoint: '/requirement/$requirementId',
          );
      state = AsyncValue.data(await _loadPlants());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}