import 'dart:convert';

import 'package:http/http.dart';
import 'package:maker_greenhouse/providers/http_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/plant_model.dart';
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
      Response response = await ref
          .read(httpServiceProvider)
          .request(method: HttpMethod.get, endpoint: '/plants/');
      final utf8Body = utf8.decode(response.bodyBytes);
      final List<dynamic> decoded = jsonDecode(utf8Body);
      return decoded.map((decodedJson) => Plant.fromJson(decodedJson)).toList();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> addPlant(Plant newPlant) async {
    try {
      Response response = await ref.read(httpServiceProvider).request(
        method: HttpMethod.post,
        endpoint: '/plants/addPlant',
        body: newPlant.toJson(),
      );

      if (response.statusCode == 200) {
        if (state is AsyncData<List<Plant>>) {
          final currentList = (state as AsyncData<List<Plant>>).value;
          state = AsyncValue.data([...currentList, newPlant]);
        }
      } else {
        throw Exception('Failed to add plant');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
