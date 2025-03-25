import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  final dynamic error;
  final VoidCallback onRetry;

  const ErrorScreen({
    required this.error,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 20),
            Text(
              _getUserFriendlyMessage(error),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              _getTechnicalDetails(error),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text("Spróbuj ponownie"),
            ),
            TextButton(
              onPressed: () => _showErrorDetails(context, error),
              child: const Text("Szczegóły błędu"),
            ),
          ],
        ),
      ),
    );
  }

  String _getUserFriendlyMessage(dynamic error) {
    if (error is SocketException) return "Brak połączenia z internetem";
    if (error is TimeoutException) return "Przekroczono czas oczekiwania";
    if (error is HttpException) return "Błąd serwera: ${error.message}";
    return "Coś poszło nie tak";
  }

  String _getTechnicalDetails(dynamic error) {
    return error.toString().replaceAll("Exception: ", "");
  }

  void _showErrorDetails(BuildContext context, dynamic error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Szczegóły błędu"),
        content: SelectableText(error.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
