import 'package:flutter/foundation.dart';

class RebuildCounter {
  RebuildCounter._();

  static final ValueNotifier<int> total = ValueNotifier<int>(0);

  static void increment() {
    total.value++;
  }

  static int reset() {
    final oldValue = total.value;
    total.value = 0;
    return oldValue;
  }
}
