import 'package:audioplayers/audioplayers.dart';
import 'package:collab_tasks/features/calls/data/services/call_alert_service_impl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ─── Моки ────────────────────────────────────────────────────────────────────

class MockAudioPlayer extends Mock implements AudioPlayer {}

// ─── Фиктивные аргументы для регистрации fallback'ов ──────────────────────

class FakeSource extends Fake implements Source {}

class FakeAudioContext extends Fake implements AudioContext {}

// ─────────────────────────────────────────────────────────────────────────────

/// Регистрирует заглушку для MethodChannel пакета vibration, чтобы
/// тесты не падали с "Binding has not yet been initialized".
void _stubVibrationChannel() {
  const channel = MethodChannel('vibration');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (call) async {
      switch (call.method) {
        case 'hasVibrator':
          return false; // нет вибратора → код вибрации не вызывается
        case 'vibrate':
        case 'cancel':
          return null;
        default:
          return null;
      }
    },
  );
}

void main() {
  // Инициализируем привязку Flutter, которая нужна MethodChannel'ам.
  TestWidgetsFlutterBinding.ensureInitialized();

  // Регистрируем fallback-значения для всех типов, которые передаются в моки.
  setUpAll(() {
    registerFallbackValue(FakeSource());
    registerFallbackValue(FakeAudioContext());
    registerFallbackValue(ReleaseMode.loop);
  });

  late MockAudioPlayer mockAudioPlayer;
  late CallAlertServiceImpl service;

  setUp(() {
    _stubVibrationChannel();

    mockAudioPlayer = MockAudioPlayer();

    // Настраиваем дефолтное поведение для всех вызовов, которые сервис делает.
    when(() => mockAudioPlayer.setAudioContext(any())).thenAnswer((_) async {});
    when(() => mockAudioPlayer.setReleaseMode(any())).thenAnswer((_) async {});
    when(() => mockAudioPlayer.play(any())).thenAnswer((_) async {});
    when(() => mockAudioPlayer.stop()).thenAnswer((_) async {});
    when(() => mockAudioPlayer.dispose()).thenAnswer((_) async {});

    service = CallAlertServiceImpl(audioPlayer: mockAudioPlayer);
  });

  tearDown(() async {
    // dispose() внутри сам вызывает stop() и dispose() на плеере.
    service.dispose();
    // Небольшая задержка, чтобы unawaited-future из dispose() успела отработать.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });

  // ── startOutgoingRingtone ──────────────────────────────────────────────────

  group('startOutgoingRingtone', () {
    test('вызывает stop(), configureAudioContext(), setReleaseMode(loop) и play()', () async {
      await service.startOutgoingRingtone();

      // stop() сначала, затем конфигурация и воспроизведение.
      verifyInOrder([
        () => mockAudioPlayer.stop(),
        () => mockAudioPlayer.setAudioContext(any()),
        () => mockAudioPlayer.setReleaseMode(ReleaseMode.loop),
        () => mockAudioPlayer.play(any()),
      ]);
    });

    test('воспроизводит outgoing_ringtone.mp3', () async {
      await service.startOutgoingRingtone();

      final captured = verify(() => mockAudioPlayer.play(captureAny())).captured;
      expect(captured.single, isA<AssetSource>());
      expect((captured.single as AssetSource).path, 'audio/outgoing_ringtone.mp3');
    });

    test(
      'после stop() снова применяет AudioContext (флаг _audioContextConfigured сброшен)',
      () async {
        await service.startOutgoingRingtone();
        // Сбрасываем через stop().
        await service.stop();
        clearInteractions(mockAudioPlayer);
        when(() => mockAudioPlayer.stop()).thenAnswer((_) async {});
        when(() => mockAudioPlayer.setAudioContext(any())).thenAnswer((_) async {});
        when(() => mockAudioPlayer.setReleaseMode(any())).thenAnswer((_) async {});
        when(() => mockAudioPlayer.play(any())).thenAnswer((_) async {});

        await service.startOutgoingRingtone();

        // После stop() флаг сброшен → setAudioContext() вызывается снова.
        verify(() => mockAudioPlayer.setAudioContext(any())).called(1);
      },
    );

    test('при ошибке play() вызывает _stopBestEffort и пробрасывает исключение', () async {
      when(() => mockAudioPlayer.play(any())).thenThrow(Exception('play failed'));

      await expectLater(service.startOutgoingRingtone(), throwsA(isA<Exception>()));

      // _stopBestEffort() должен был вызвать stop() ещё раз.
      verify(() => mockAudioPlayer.stop()).called(greaterThanOrEqualTo(1));
    });
  });

  // ── startIncomingRingtone ──────────────────────────────────────────────────

  group('startIncomingRingtone', () {
    test('вызывает stop(), configureAudioContext(), setReleaseMode(loop) и play()', () async {
      await service.startIncomingRingtone();

      verifyInOrder([
        () => mockAudioPlayer.stop(),
        () => mockAudioPlayer.setAudioContext(any()),
        () => mockAudioPlayer.setReleaseMode(ReleaseMode.loop),
        () => mockAudioPlayer.play(any()),
      ]);
    });

    test('воспроизводит incoming_ringtone.mp3', () async {
      await service.startIncomingRingtone();

      final captured = verify(() => mockAudioPlayer.play(captureAny())).captured;
      expect(captured.single, isA<AssetSource>());
      expect((captured.single as AssetSource).path, 'audio/incoming_ringtone.mp3');
    });

    test('при ошибке play() вызывает _stopBestEffort и пробрасывает исключение', () async {
      when(() => mockAudioPlayer.play(any())).thenThrow(Exception('play failed'));

      await expectLater(service.startIncomingRingtone(), throwsA(isA<Exception>()));

      verify(() => mockAudioPlayer.stop()).called(greaterThanOrEqualTo(1));
    });
  });

  // ── stop ──────────────────────────────────────────────────────────────────

  group('stop', () {
    test('вызывает audioPlayer.stop()', () async {
      await service.stop();

      verify(() => mockAudioPlayer.stop()).called(1);
    });

    test(
      'сбрасывает _audioContextConfigured, чтобы следующий start() переприменял контекст',
      () async {
        // Сначала запустим, чтобы выставить флаг.
        await service.startOutgoingRingtone();
        clearInteractions(mockAudioPlayer);
        when(() => mockAudioPlayer.stop()).thenAnswer((_) async {});
        when(() => mockAudioPlayer.setAudioContext(any())).thenAnswer((_) async {});
        when(() => mockAudioPlayer.setReleaseMode(any())).thenAnswer((_) async {});
        when(() => mockAudioPlayer.play(any())).thenAnswer((_) async {});

        // stop() должен сбросить флаг.
        await service.stop();
        clearInteractions(mockAudioPlayer);
        when(() => mockAudioPlayer.stop()).thenAnswer((_) async {});
        when(() => mockAudioPlayer.setAudioContext(any())).thenAnswer((_) async {});
        when(() => mockAudioPlayer.setReleaseMode(any())).thenAnswer((_) async {});
        when(() => mockAudioPlayer.play(any())).thenAnswer((_) async {});

        await service.startOutgoingRingtone();

        // Контекст применяется снова.
        verify(() => mockAudioPlayer.setAudioContext(any())).called(1);
      },
    );

    test('пробрасывает первую ошибку, если audioPlayer.stop() бросает', () async {
      when(() => mockAudioPlayer.stop()).thenThrow(Exception('stop failed'));

      await expectLater(service.stop(), throwsA(isA<Exception>()));
    });
  });

  // ── dispose ───────────────────────────────────────────────────────────────

  group('dispose', () {
    test('вызывает stop() и audioPlayer.dispose()', () async {
      service.dispose();
      // Даём unawaited-future завершиться.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => mockAudioPlayer.stop()).called(greaterThanOrEqualTo(1));
      verify(() => mockAudioPlayer.dispose()).called(1);
    });

    test('не пробрасывает ошибку, если stop() внутри dispose() упал', () async {
      // Ошибка при stop() во время dispose() должна быть поглощена, а dispose()
      // плеера — всё равно вызван.
      when(() => mockAudioPlayer.stop()).thenThrow(Exception('stop in dispose failed'));

      service.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // dispose() плеера всё равно вызван, несмотря на ошибку stop().
      verify(() => mockAudioPlayer.dispose()).called(1);
    });
  });
}
