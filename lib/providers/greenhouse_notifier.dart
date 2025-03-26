import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/greenhouse_model.dart';
import '../models/greenhouse_status_model.dart';
import '../models/plant_model.dart';

part 'greenhouse_notifier.g.dart';

///TODO: add api call
@riverpod
class GreenhouseNotifier extends _$GreenhouseNotifier {
  @override
  Future<List<Greenhouse>> build() async {
    try {
      // Replace with actual API call
      await Future.delayed(
          const Duration(seconds: 1)); // Simulate network delay

      return _dummyData(); // Temporary until API implementation
    } catch (e, st) {
      throw AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _dummyData(); // Replace with API call
    });
  }

  List<Greenhouse> _dummyData() {
    return [
      Greenhouse(
        name: "Greenhouse1",
        location: "horn",
        ipAddress: "1.1.1.1",
        greenhouseStatus: GreenhouseStatus(
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
        name: "Srenhouse1",
        location: "horn",
        ipAddress: "1.1.1.1",
        greenhouseStatus: GreenhouseStatus(
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
        name: "Srenhouse5",
        location: "horn",
        ipAddress: "1.1.1.1",
        greenhouseStatus: GreenhouseStatus(
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
