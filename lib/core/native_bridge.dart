import 'package:flutter/services.dart';

class NativeBridge {
  NativeBridge({MethodChannel? channel})
    : channel =
          channel ?? const MethodChannel('com.sorayaferreira.vaiviver/native');

  final MethodChannel channel;
}
