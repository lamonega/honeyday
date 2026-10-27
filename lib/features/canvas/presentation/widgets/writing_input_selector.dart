import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/features/canvas/domain/writing_input.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

class WritingInputSelector extends ConsumerWidget {
  const WritingInputSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(writingInputProvider);
    final l10n = AppLocalizations.of(context);

    return SegmentedButton<WritingInput>(
      segments: [
        ButtonSegment(
          value: WritingInput.content,
          icon: const Icon(Icons.touch_app_outlined),
          label: Text(l10n.canvasInputContent),
        ),
        ButtonSegment(
          value: WritingInput.ink,
          icon: const Icon(Icons.draw_outlined),
          label: Text(l10n.canvasInputInk),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (values) {
        FocusManager.instance.primaryFocus?.unfocus();
        ref.read(writingInputProvider.notifier).select(values.single);
      },
    );
  }
}
