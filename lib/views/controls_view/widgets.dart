import 'package:flutter/material.dart';

import '../../models/greenhouse_model.dart';
import '../../models/greenhouse_status_model.dart';

class GreenhouseStatusIndicator extends StatelessWidget {
  const GreenhouseStatusIndicator({
    Key? key,
    required this.greenhouseStatus,
  }) : super(key: key);

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
    return Container(
      child: Column(
        children: [
          Text(greenhouse.name),
          Text("Location: ${greenhouse.location}"),
          if (greenhouse.greenhouseStatus != null)
            GreenhouseStatusIndicator(
                greenhouseStatus: greenhouse.greenhouseStatus!.status),
        ],
      ),
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
