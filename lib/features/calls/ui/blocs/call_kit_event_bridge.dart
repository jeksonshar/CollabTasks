import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';

/// Forwards the one CallKit plugin stream owned by a CallsBloc instance.
/// The Bloc creates and disposes this bridge alongside its own lifecycle.
class CallKitEventBridge {
  CallKitEventBridge({
    required Stream<CallEvent?>? events,
    required void Function(CallEvent event) onEvent,
  }) : _subscription = events?.listen(
         (event) {
           if (event != null) onEvent(event);
         },
         onError: (Object error, StackTrace stackTrace) {
           debugPrint('[CallsBloc] CallKit event stream error: $error\n$stackTrace');
         },
       );

  final StreamSubscription<CallEvent?>? _subscription;

  Future<void> close() async {
    await _subscription?.cancel();
  }
}
