// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import '../../models/plant_model.dart';
// import '../../providers/plant_list_controller_provider.dart';
//
// class AddPlantView extends ConsumerStatefulWidget {
//   const AddPlantView({Key? key}) : super(key: key);
//
//   @override
//   ConsumerState<AddPlantView> createState() => _AddPlantViewState();
// }
//
// class _AddPlantViewState extends ConsumerState<AddPlantView> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _specialNeedsController = TextEditingController();
//   final _humidityController = TextEditingController();
//   final _temperatureController = TextEditingController();
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _descriptionController.dispose();
//     _specialNeedsController.dispose();
//     _humidityController.dispose();
//     _temperatureController.dispose();
//     super.dispose();
//   }
//
//   void _addPlant() {
//     if (_formKey.currentState?.validate() ?? false) {
//       final newPlant = Plant(
//         id: DateTime.now().millisecondsSinceEpoch,
//         name: _nameController.text,
//         description: _descriptionController.text,
//         special_needs: _specialNeedsController.text,
//         required_humidity: _humidityController.text,
//         required_temperature: _temperatureController.text,
//       );
//
//       ref.read(plantListNotifierProvider.notifier).addPlant(newPlant);
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Plant added successfully!')),
//       );
//
//       // Clear the form
//       _nameController.clear();
//       _descriptionController.clear();
//       _specialNeedsController.clear();
//       _humidityController.clear();
//       _temperatureController.clear();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Add New Plant'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               TextFormField(
//                 controller: _nameController,
//                 decoration: const InputDecoration(labelText: 'Name'),
//                 validator: (value) =>
//                     value?.isEmpty ?? true ? 'Name is required' : null,
//               ),
//               TextFormField(
//                 controller: _descriptionController,
//                 decoration: const InputDecoration(labelText: 'Description'),
//                 validator: (value) =>
//                     value?.isEmpty ?? true ? 'Description is required' : null,
//               ),
//               TextFormField(
//                 controller: _specialNeedsController,
//                 decoration: const InputDecoration(labelText: 'Special Needs'),
//                 validator: (value) => value?.isEmpty ?? true
//                     ? 'Special Needs description is required'
//                     : null,
//               ),
//               TextFormField(
//                 controller: _humidityController,
//                 decoration:
//                     const InputDecoration(labelText: 'Humidity (e.g., 60%)'),
//                 validator: (value) =>
//                     value?.isEmpty ?? true ? 'Humidity is required' : null,
//               ),
//               TextFormField(
//                 controller: _temperatureController,
//                 decoration:
//                     const InputDecoration(labelText: 'Temperature (°C)'),
//                 validator: (value) =>
//                     value?.isEmpty ?? true ? 'Temperature is required' : null,
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _addPlant,
//                 child: const Text('Add Plant'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
