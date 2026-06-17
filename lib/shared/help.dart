import 'package:flutter/material.dart';

import '../generated/l10n.dart';

/// A small "?" icon button that opens a scrollable help sheet describing a
/// configuration concept or field. Use [compact] for inline placement next to
/// a form field or section header.
class HelpButton extends StatelessWidget {
  const HelpButton({
    super.key,
    required this.title,
    required this.body,
    this.compact = false,
  });

  final String title;
  final String body;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.help_outline),
      iconSize: compact ? 18 : 24,
      visualDensity: compact ? VisualDensity.compact : null,
      padding: compact ? EdgeInsets.zero : null,
      constraints: compact ? const BoxConstraints() : null,
      tooltip: title,
      onPressed: () => showHelpSheet(context, title, body),
    );
  }
}

/// Opens a bottom sheet with a help [title] and [body]. The body may contain
/// newlines and bullet characters; it is rendered as plain wrapped text.
Future<void> showHelpSheet(BuildContext context, String title, String body) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (ctx, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text(
            title,
            style: Theme.of(ctx)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(S.of(ctx).helpClose),
            ),
          ),
        ],
      ),
    ),
  );
}
