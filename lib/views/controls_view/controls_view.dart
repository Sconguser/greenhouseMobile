import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maker_greenhouse/providers/greenhouse_notifier.dart';
import 'package:maker_greenhouse/shared/loading_indicator.dart';
import 'package:maker_greenhouse/views/controls_view/widgets.dart';

import '../../models/greenhouse_model.dart';

class ControlsView extends ConsumerWidget {
  const ControlsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    final greenhousesAsync = ref.watch(greenhouseNotifierProvider);
    return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: height * 0.9, maxWidth: width * 0.8),
          child: greenhousesAsync.when(
              data: (List<Greenhouse> data) => _buildListView(data),
              error: (Object error, StackTrace stackTrace) =>
                  _buildError(ref, error),
              loading: () => const LoadingIndicatorWidget()),
        ));
  }

  Widget _buildError(WidgetRef ref, Object error) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Error: ${error.toString()}'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () =>
              ref.read(greenhouseNotifierProvider.notifier).refresh(),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  ListView _buildListView(List<Greenhouse> greenhouses) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: greenhouses.length + 1, // Add 1 for the button
      itemBuilder: (context, index) {
        // If the index is the last one, return the button
        if (index == greenhouses.length) {
          return GestureDetector(
            onTap: () {
              // Navigator.pushNamed(
              //     context, '/add'); // Redirect to Add Plant View
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: const Icon(Icons.add),
            ),
          );
        }

        final greenhouse = greenhouses[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: GreenhouseTile(greenhouse: greenhouse),
        );
      },
    );
  }
}
