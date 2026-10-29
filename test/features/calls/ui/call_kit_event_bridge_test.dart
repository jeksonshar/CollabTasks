import 'dart:async';

import 'package:collab_tasks/features/calls/ui/blocs/bloc_components/call_kit_event_bridge.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forwards each non-null event from its single stream subscription', () async {
    final events = StreamController<CallEvent?>();
    final received = <CallEvent>[];
    const timeout = CallEventActionCallTimeout('call-1');
    final bridge = CallKitEventBridge(events: events.stream, onEvent: received.add);

    events
      ..add(timeout)
      ..add(null);
    await Future<void>.delayed(Duration.zero);

    expect(received, [same(timeout)]);
    await bridge.close();
    await events.close();
  });

  test('close cancels forwarding from the plugin stream', () async {
    final events = StreamController<CallEvent?>();
    final received = <CallEvent>[];
    final bridge = CallKitEventBridge(events: events.stream, onEvent: received.add);

    await bridge.close();
    events.add(const CallEventActionCallTimeout('call-after-close'));
    await Future<void>.delayed(Duration.zero);

    expect(received, isEmpty);
    await events.close();
  });
}
