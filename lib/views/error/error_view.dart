import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../../generated/l10n.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        // Constrain to 80% of available height to prevent overflow
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 600, // Optional: Limit width for larger screens
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Collapse vertically if content is small
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            // Flexible text to avoid overflow
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(S.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}
