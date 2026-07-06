import 'package:flutter/material.dart';

class ReleaseNotesView extends StatelessWidget {
  final String notes;

  const ReleaseNotesView({
    super.key,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = notes.trim();
    if (normalized.isEmpty) {
      return const Text('Sin notas disponibles.');
    }

    final lines = normalized.replaceAll('\r\n', '\n').split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines) _buildLine(context, line),
      ],
    );
  }

  Widget _buildLine(BuildContext context, String rawLine) {
    final line = rawLine.trimRight();

    if (line.trim().isEmpty) {
      return const SizedBox(height: 10);
    }

    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 6),
        child: Text(
          line.substring(3).trim(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      );
    }

    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: Text(
          line.substring(2).trim(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      );
    }

    if (line.startsWith('- ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4, right: 8),
              child: Icon(
                Icons.circle,
                size: 7,
                color: Color(0xFF46515C),
              ),
            ),
            Expanded(
              child: _InlineMarkdownText(
                text: line.substring(2).trim(),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: _InlineMarkdownText(text: line.trim()),
    );
  }
}

class _InlineMarkdownText extends StatelessWidget {
  final String text;

  const _InlineMarkdownText({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: _buildSpans(context, text),
      ),
    );
  }

  List<InlineSpan> _buildSpans(BuildContext context, String source) {
    final spans = <InlineSpan>[];
    final matches = RegExp(r'(\*\*.*?\*\*|`.*?`)').allMatches(source);
    var currentIndex = 0;

    for (final match in matches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: source.substring(currentIndex, match.start)));
      }

      final token = match.group(0) ?? '';
      if (token.startsWith('**') && token.endsWith('**') && token.length >= 4) {
        spans.add(
          TextSpan(
            text: token.substring(2, token.length - 2),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      } else if (token.startsWith('`') &&
          token.endsWith('`') &&
          token.length >= 2) {
        spans.add(
          TextSpan(
            text: token.substring(1, token.length - 1),
            style: TextStyle(
              fontFamily: 'monospace',
              backgroundColor: Colors.black.withValues(alpha: 0.06),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: token));
      }

      currentIndex = match.end;
    }

    if (currentIndex < source.length) {
      spans.add(TextSpan(text: source.substring(currentIndex)));
    }

    return spans;
  }
}
