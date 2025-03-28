import 'package:another_xlider/another_xlider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../generated/l10n.dart';
import '../../models/greenhouse_model.dart';
import '../../models/greenhouse_status_model.dart';
import '../../models/plant_model.dart';

const String humidityUnit = "%";
const String temperatureUnit = "℃";

class GreenhouseStatusIndicator extends StatelessWidget {
  const GreenhouseStatusIndicator({
    super.key,
    required this.greenhouseStatus,
  });

  final Status greenhouseStatus;

  @override
  Widget build(BuildContext context) {
    switch (greenhouseStatus) {
      case Status.ON:
        return Icon(
          Icons.ac_unit,
          color: Colors.green,
        );
      case Status.OFF:
        return Icon(
          Icons.ac_unit,
          color: Colors.red,
        );
      case Status.NOT_RESPONSIVE:
        return Icon(
          Icons.ac_unit,
          color: Colors.blue,
        );
    }
  }
}

class GreenhouseTile extends StatelessWidget {
  const GreenhouseTile({Key? key, required this.greenhouse}) : super(key: key);

  final Greenhouse greenhouse;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        title: Text(
          greenhouse.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(S.of(context).controlsLocation(greenhouse.location)),
        children: [
          if (greenhouse.greenhouseStatus != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  GreenhouseStatusPanel(
                      greenhouseStatus: greenhouse.greenhouseStatus!),
                  GreenhouseControlPanel(
                      greenhouseStatus: greenhouse.greenhouseStatus!),
                ],
              ),
            ),
          ElevatedButton(
            onPressed: () {
              showMaterialModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Container(
                      child: Text("dupa"),
                    );
                  });
            },
            child: Text("Add new plant"),
          ),
          ...greenhouse.plants.map((plant) => PlantTile(
                plant: plant,
              )),
        ],
      ),
    );
  }
}

class PlantTile extends StatelessWidget {
  const PlantTile({super.key, required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.local_florist),
      title: Text(plant.name),
      subtitle: Text(S.of(context).controlsDescription(plant.description)),
    );
  }
}

class GreenhouseControlPanel extends ConsumerStatefulWidget {
  const GreenhouseControlPanel({Key? key, required this.greenhouseStatus})
      : super(key: key);
  final GreenhouseStatus greenhouseStatus;

  @override
  ConsumerState<GreenhouseControlPanel> createState() =>
      _GreenhouseControlPanelState();
}

class _GreenhouseControlPanelState
    extends ConsumerState<GreenhouseControlPanel> {
  double newTemperature = 0.0; // Store in state
  double newHumidity = 0.0;
  double newSoilHumidity = 0.0;

  @override
  void initState() {
    super.initState();
    newTemperature = widget.greenhouseStatus.temperature;
    newHumidity = widget.greenhouseStatus.humidity;
    newSoilHumidity = widget.greenhouseStatus.soilHumidity;
  }

  @override
  Widget build(BuildContext context) {
    double currentTemperature = widget.greenhouseStatus.temperature;
    double currentHumidity = widget.greenhouseStatus.humidity;
    double currentSoilHumidity = widget.greenhouseStatus.soilHumidity;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ExpansionTile(
          title: Text(
            S.of(context).controlsControlPanel,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [
            Column(
              children: [
                _buildTemperatureColumn(),
                _buildHumidityColumn(),
                _buildSoilHumidityColumn(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildChangesConfirmationButton(currentSoilHumidity,
                        currentTemperature, currentHumidity, context),
                    _buildChangesResetButton(currentHumidity,
                        currentTemperature, currentSoilHumidity, context)
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  ElevatedButton _buildChangesResetButton(
      double currentHumidity,
      double currentTemperature,
      double currentSoilHumidity,
      BuildContext context) {
    return ElevatedButton(
        onPressed: () {
          setState(() {
            newHumidity = currentHumidity;
            newTemperature = currentTemperature;
            newSoilHumidity = currentSoilHumidity;
          });
        },
        child: Text(S.of(context).controlsResetChange));
  }

  ElevatedButton _buildChangesConfirmationButton(double currentSoilHumidity,
      double currentTemperature, double currentHumidity, BuildContext context) {
    return ElevatedButton(
      onPressed: (currentSoilHumidity != newSoilHumidity ||
              currentTemperature != newTemperature ||
              currentHumidity != newHumidity)
          ? () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(S.of(context).controlsDialogTitle),
                  content: Text(S.of(context).controlsDialogContent),
                  actions: [
                    TextButton(
                      child: Text(S.of(context).controlsDialogReject),
                      onPressed: () {},
                    ),
                    TextButton(
                      child: Text(S.of(context).controlsDialogAccept),
                      onPressed: () {},
                    ),
                  ],
                ),
                barrierDismissible: true,
              );
            }
          : null,
      child: Text(S.of(context).controlsConfirmChange),
    );
  }

  Column _buildSoilHumidityColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.current.soilHumidity),
        Row(
          children: [
            Expanded(
              child: FlutterSlider(
                values: [newSoilHumidity],
                max: 100,
                min: 0,
                onDragging: (handlerIndex, lowerValue, upperValue) {
                  setState(() {
                    newSoilHumidity = lowerValue;
                  });
                },
              ),
            ),
            Text("$newSoilHumidity $humidityUnit"),
          ],
        ),
      ],
    );
  }

  Column _buildHumidityColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.current.humidity),
        Row(
          children: [
            Expanded(
              child: FlutterSlider(
                values: [newHumidity],
                max: 100,
                min: 0,
                onDragging: (handlerIndex, lowerValue, upperValue) {
                  setState(() {
                    newHumidity = lowerValue;
                  });
                },
              ),
            ),
            Text("$newHumidity $humidityUnit"),
          ],
        ),
      ],
    );
  }

  Column _buildTemperatureColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.current.temperature),
        Row(
          children: [
            Expanded(
              child: FlutterSlider(
                values: [newTemperature],
                max: 100,
                min: 0,
                onDragging: (handlerIndex, lowerValue, upperValue) {
                  setState(() {
                    newTemperature = lowerValue;
                  });
                },
              ),
            ),
            Text("$newTemperature $temperatureUnit"),
          ],
        ),
      ],
    );
  }
}

class GreenhouseStatusPanel extends StatelessWidget {
  const GreenhouseStatusPanel({
    super.key,
    required this.greenhouseStatus,
  });

  final GreenhouseStatus greenhouseStatus;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(S.of(context).controlsStatus),
        GreenhouseStatusIndicator(
          greenhouseStatus: greenhouseStatus.status,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "${S.of(context).controlsTemperature(greenhouseStatus.temperature)} $temperatureUnit"),
            Text(
                "${S.of(context).controlsHumidity(greenhouseStatus.humidity)} $humidityUnit"),
            Text(
                "${S.of(context).controlsSoilHumidity(greenhouseStatus.soilHumidity)} $humidityUnit"),
          ],
        )
      ],
    );
  }
}
// class PlantTile extends StatelessWidget {
//   const PlantTile({
//     Key? key,
//     required this.plant,
//   }) : super(key: key);
//
//   final Plant plant;
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => PlantDetailsPage(plant: plant),
//           ),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 10),
//         padding: const EdgeInsets.all(16),
//         color: Colors.transparent,
//         child: Row(
//           children: [
//             // Image of the plant
//             if (plant.image_url != null)
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: Image.network(
//                   plant.image_url!,
//                   width: 60,
//                   height: 60,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             if (plant.image_url != null) const SizedBox(width: 12),
//             // Plant details
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     plant.name,
//                     style: Theme.of(context).textTheme.titleMedium,
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     plant.description,
//                     style: Theme.of(context)
//                         .textTheme
//                         .bodySmall
//                         ?.copyWith(color: Colors.grey[600]),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class PlantDetails extends StatelessWidget {
//   const PlantDetails({
//     Key? key,
//     required this.name,
//     required this.description,
//     required this.specialNeeds,
//     required this.requiredTemperature,
//     required this.requiredHumidity,
//     this.imageUrl,
//   }) : super(key: key);
//
//   final String name;
//   final String description;
//   final String specialNeeds;
//   final String requiredTemperature;
//   final String requiredHumidity;
//   final String? imageUrl;
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Optional Image
//             if (imageUrl != null)
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: Image.network(imageUrl!),
//               ),
//             const SizedBox(height: 16),
//             // Plant Information
//             Text(name, style: Theme.of(context).textTheme.headlineSmall),
//             const SizedBox(height: 8),
//             Text(description, style: Theme.of(context).textTheme.bodyMedium),
//             const SizedBox(height: 16),
//             Text(
//               'Special Needs: $specialNeeds',
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Humidity: $requiredHumidity',
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Temperature: $requiredTemperature',
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class PlantDetailsPage extends StatelessWidget {
//   const PlantDetailsPage({
//     Key? key,
//     required this.plant,
//   }) : super(key: key);
//
//   final Plant plant;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(plant.name),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Display Image
//               if (plant.image_url != null)
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: Image.network(
//                     plant.image_url!,
//                     width: double.infinity,
//                     height: 200,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               const SizedBox(height: 16),
//               // Plant Details
//               Text(plant.name,
//                   style: Theme.of(context).textTheme.headlineSmall),
//               const SizedBox(height: 8),
//               Text(
//                 plant.description,
//                 style: Theme.of(context).textTheme.bodyMedium,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Special Needs: ${plant.special_needs}',
//                 style: Theme.of(context).textTheme.bodyMedium,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Humidity: ${plant.required_humidity}',
//                 style: Theme.of(context).textTheme.bodyMedium,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Temperature: ${plant.required_temperature}',
//                 style: Theme.of(context).textTheme.bodyMedium,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
