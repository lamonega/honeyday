import 'package:flutter_riverpod/flutter_riverpod.dart';

enum WritingInput { content, ink }

class WritingInputNotifier extends Notifier<WritingInput> {
  @override
  WritingInput build() => WritingInput.ink;

  WritingInput get selected => state;
  set selected(WritingInput input) => state = input;
}

final writingInputProvider =
    NotifierProvider<WritingInputNotifier, WritingInput>(
      WritingInputNotifier.new,
    );
