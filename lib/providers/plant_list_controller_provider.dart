// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import '../models/plant_model.dart';
//
// class PlantListNotifier extends StateNotifier<List<Plant>> {
//   PlantListNotifier(List<Plant> state, this.ref) : super(state);
//   final Ref ref;
//
//   void addPlant(Plant plant) {
//     state = [...state, plant];
//   }
// }
//
// final plantListNotifierProvider =
//     StateNotifierProvider<PlantListNotifier, List<Plant>>(
//         (ref) => PlantListNotifier([
//               Plant(
//                   id: 0,
//                   name: "Monstera",
//                   description: "Straszna",
//                   special_needs: "Brak",
//                   required_temperature: "35",
//                   required_humidity: "60"),
//               Plant(
//                   id: 1,
//                   name: "Bluszcz",
//                   description: "Niestraszny",
//                   special_needs: "Dużo słońca",
//                   required_temperature: "35",
//                   required_humidity: "60"),
//               Plant(
//                   id: 2,
//                   name: "Mandarynka",
//                   description: "Smaczna",
//                   special_needs: "Bardzo wrażliwa na zmiany temperatury",
//                   required_temperature: "40",
//                   required_humidity: "80"),
//               Plant(
//                   id: 3,
//                   name: "Monstera",
//                   description: "Straszna",
//                   special_needs: "Brak",
//                   required_temperature: "35",
//                   required_humidity: "60"),
//               Plant(
//                   id: 4,
//                   name: "Monstera",
//                   description: "Straszna",
//                   special_needs: "Brak",
//                   required_temperature: "35",
//                   required_humidity: "60"),
//             ], ref));
