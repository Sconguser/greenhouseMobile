import 'dart:convert';

import 'package:http/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/greenhouse_model.dart';
import '../models/greenhouse_status_model.dart';
import '../models/plant_model.dart';
import 'http_conf.dart';
import 'http_service.dart';

part 'greenhouse_notifier.g.dart';

@riverpod
class GreenhouseNotifier extends _$GreenhouseNotifier {
  @override
  Future<List<Greenhouse>> build() async {
    return _loadGreenhouses();
  }

  Future<List<Greenhouse>> _loadGreenhouses() async {
    state = AsyncValue.loading();
    try {
      Response response = await ref
          .read(httpServiceProvider)
          .request(method: HttpMethod.get, endpoint: "/greenhouse/");
      final utf8Body = utf8.decode(response.bodyBytes);
      final List<dynamic> decoded = jsonDecode(utf8Body);
      return decoded
          .map((decodedGreenhouse) => Greenhouse.fromJson(decodedGreenhouse))
          .toList();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<Greenhouse> _fetchSingleGreenhouse(int id) async {
    state = AsyncValue.loading();
    try {
      Response response = await ref
          .read(httpServiceProvider)
          .request(method: HttpMethod.get, endpoint: "/greenhouse/$id");
      final utf8Body = utf8.decode(response.bodyBytes);
      return Greenhouse.fromJson(jsonDecode(utf8Body));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  // Future<void> refresh() async {
  //   state = const AsyncValue.loading();
  //   state = await AsyncValue.guard(() async {
  //     return _dummyData(); // Replace with API call
  //   });
  // }

  Future<void> editGreenhouse(Greenhouse greenhouse, int greenhouseId) async {
    List<Greenhouse>? previousState;
    if (state is AsyncData<List<Greenhouse>>) {
      previousState = (state as AsyncData<List<Greenhouse>>).value;
    }
    state = AsyncValue.loading();
    try {
      Response response = await ref.read(httpServiceProvider).request(
          method: HttpMethod.patch,
          endpoint: '/greenhouse/$greenhouseId',
          body: greenhouse.toJson());
      if (response.statusCode == 200) {
        if (previousState != null) {
          final utf8Body = utf8.decode(response.bodyBytes);
          Greenhouse edited = Greenhouse.fromJson(jsonDecode(utf8Body));
          previousState
              .removeWhere((greenhouse) => greenhouse.id == greenhouseId);
          previousState.add(edited);
          state = AsyncValue.data(previousState);
        } else {
          state = AsyncValue.data(await _loadGreenhouses());
        }
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> addNewGreenhouse(Greenhouse greenhouse) async {
    List<Greenhouse>? previousState;
    if (state is AsyncData<List<Greenhouse>>) {
      previousState = (state as AsyncData<List<Greenhouse>>).value;
    }
    state = AsyncValue.loading();
    try {
      Response response = await ref.read(httpServiceProvider).request(
          method: HttpMethod.post,
          endpoint: "/greenhouse/add",
          body: greenhouse.toJson());
      if (response.statusCode == 200) {
        state = AsyncValue.data(await _loadGreenhouses());
      } else {
        throw Exception('Failed to add plant');
      }
    } catch (exception, stackTrace) {
      state = AsyncError(exception, stackTrace);
      rethrow;
    }
  }

  Future<void> addNewPlantToGreenhouse(Plant plant, int id) async {
    List<Greenhouse>? previousState;
    if (state is AsyncData<List<Greenhouse>>) {
      previousState = (state as AsyncData<List<Greenhouse>>).value;
    }
    state = AsyncValue.loading();
    try {
      Response response = await ref.read(httpServiceProvider).request(
            method: HttpMethod.post,
            endpoint: '/greenhouse/addPlant/$id',
            body: plant.toJson(),
          );
      if (response.statusCode == 200) {
        if (previousState != null) {
          Greenhouse modifiedGreenhouse = await _fetchSingleGreenhouse(id);
          previousState.removeWhere((greenhouse) => greenhouse.id == id);
          state = AsyncValue.data([...previousState, modifiedGreenhouse]);
        } else {
          state = AsyncValue.data(await _loadGreenhouses());
        }
      } else {
        throw Exception('Failed to add plant to greenhouse');
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  List<Greenhouse> _dummyData() {
    return [
      Greenhouse(
        id: 1,
        name: "Greenhouse1",
        location: "horn",
        ipAddress: "1.1.1.1",
        status: GreenhouseStatus(
            temperature: 50, humidity: 30, soilHumidity: 30, status: Status.ON),
        plants: [
          Plant(
            name: "Monstera",
            description: 'Straszna',
            minTemperature: 20,
            maxTemperature: 40,
            minHumidity: 20,
            maxHumidity: 80,
            minSoilHumidity: 30,
            maxSoilHumidity: 70,
          ),
          Plant(
            name: "Fikus",
            description: 'Malo straszny',
            minTemperature: 20,
            maxTemperature: 40,
            minHumidity: 20,
            maxHumidity: 80,
            minSoilHumidity: 30,
            maxSoilHumidity: 70,
          ),
          Plant(
            name: "Malpa",
            description: 'nie lubie malp',
            minTemperature: 20,
            maxTemperature: 40,
            minHumidity: 20,
            maxHumidity: 80,
            minSoilHumidity: 30,
            maxSoilHumidity: 70,
          ),
        ],
      ),
      Greenhouse(
        id: 2,
        name: "Srenhouse1",
        location: "horn",
        ipAddress: "1.1.1.1",
        status: GreenhouseStatus(
            temperature: 50, humidity: 30, soilHumidity: 30, status: Status.ON),
        plants: [
          Plant(
            name: "Monstera",
            description: 'Straszna',
            minTemperature: 20,
            maxTemperature: 40,
            minHumidity: 20,
            maxHumidity: 80,
            minSoilHumidity: 30,
            maxSoilHumidity: 70,
          ),
          Plant(
            name: "Fikus",
            description: 'Malo straszny',
            minTemperature: 20,
            maxTemperature: 40,
            minHumidity: 20,
            maxHumidity: 80,
            minSoilHumidity: 30,
            maxSoilHumidity: 70,
          ),
          Plant(
            name: "Malpa",
            description: 'nie lubie malp',
            minTemperature: 20,
            maxTemperature: 40,
            minHumidity: 20,
            maxHumidity: 80,
            minSoilHumidity: 30,
            maxSoilHumidity: 70,
          ),
        ],
      ),
      Greenhouse(
        id: 3,
        name: "Srenhouse5",
        location: "horn",
        ipAddress: "1.1.1.1",
        status: GreenhouseStatus(
            temperature: 50, humidity: 30, soilHumidity: 30, status: Status.ON),
        plants: [
          Plant(
            name: "Monstera",
            description: 'Straszna',
            minTemperature: 20,
            maxTemperature: 40,
            minHumidity: 20,
            maxHumidity: 80,
            minSoilHumidity: 30,
            maxSoilHumidity: 70,
          ),
          Plant(
            name: "Fikus",
            description: 'Malo straszny',
            minTemperature: 20,
            maxTemperature: 40,
            minHumidity: 20,
            maxHumidity: 80,
            minSoilHumidity: 30,
            maxSoilHumidity: 70,
          ),
          Plant(
            name: "Malpa",
            description: 'nie lubie malp',
            minTemperature: 20,
            maxTemperature: 40,
            minHumidity: 20,
            maxHumidity: 80,
            minSoilHumidity: 30,
            maxSoilHumidity: 70,
          ),
        ],
      )
    ];
  }
}
