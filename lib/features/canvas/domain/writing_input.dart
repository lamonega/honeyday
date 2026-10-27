import 'package:flutter_riverpod/flutter_riverpod.dart';

enum WritingInput { content, ink }

class WritingInputNotifier extends Notifier<WritingInput> {
  @override
  WritingInput build() => WritingInput.ink;

  void select(WritingInput input) => state = input;
}

final writingInputProvider =
    NotifierProvider<WritingInputNotifier, WritingInput>(
  WritingInputNotifier.new,
);
