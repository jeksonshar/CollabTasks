import 'package:bloc_test/bloc_test.dart';
import 'package:collab_tasks/features/settings/domain/models/theme_preference.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/get_theme_preference_use_case.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/set_theme_preference_use_case.dart';
import 'package:collab_tasks/features/settings/ui/blocs/theme_bloc/theme_bloc.dart';
import 'package:collab_tasks/features/settings/ui/blocs/theme_bloc/theme_event.dart';
import 'package:collab_tasks/features/settings/ui/blocs/theme_bloc/theme_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetThemePreferenceUseCase extends Mock implements GetThemePreferenceUseCase {}

class MockSetThemePreferenceUseCase extends Mock implements SetThemePreferenceUseCase {}

class FakeThemePreference extends Fake implements ThemePreference {
  @override
  final AppThemeMode mode = AppThemeMode.system;

  @override
  String toMap() => mode.name;

  @override
  List<Object?> get props => [mode];
}

void main() {
  late MockGetThemePreferenceUseCase mockGetThemePreferenceUseCase;
  late MockSetThemePreferenceUseCase mockSetThemePreferenceUseCase;

  setUpAll(() {
    registerFallbackValue(FakeThemePreference());
  });

  setUp(() {
    mockGetThemePreferenceUseCase = MockGetThemePreferenceUseCase();
    mockSetThemePreferenceUseCase = MockSetThemePreferenceUseCase();
  });

  group('ThemeBloc', () {
    test('initial state is ThemeState with system theme mode', () {
      when(
        () => mockGetThemePreferenceUseCase(),
      ).thenAnswer((_) async => const ThemePreference(mode: AppThemeMode.system));

      final themeBloc = ThemeBloc(
        getThemePreferenceUseCase: mockGetThemePreferenceUseCase,
        setThemePreferenceUseCase: mockSetThemePreferenceUseCase,
      );

      expect(themeBloc.state.themePreference.mode, equals(AppThemeMode.system));
    });

    blocTest<ThemeBloc, ThemeState>(
      'emits new state when theme preference is loaded successfully',
      setUp: () {
        when(
          () => mockGetThemePreferenceUseCase(),
        ).thenAnswer((_) async => const ThemePreference(mode: AppThemeMode.dark));
      },
      build: () => ThemeBloc(
        getThemePreferenceUseCase: mockGetThemePreferenceUseCase,
        setThemePreferenceUseCase: mockSetThemePreferenceUseCase,
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.system),
          isLoading: true,
        ),
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.dark),
          isLoading: false,
        ),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'emits new state when theme mode is changed to light',
      setUp: () {
        when(
          () => mockGetThemePreferenceUseCase(),
        ).thenAnswer((_) async => const ThemePreference(mode: AppThemeMode.system));
        when(() => mockSetThemePreferenceUseCase(any())).thenAnswer((_) async => {});
      },
      build: () => ThemeBloc(
        getThemePreferenceUseCase: mockGetThemePreferenceUseCase,
        setThemePreferenceUseCase: mockSetThemePreferenceUseCase,
      ),
      act: (bloc) => bloc.add(const ThemeModeChanged(ThemePreference(mode: AppThemeMode.light))),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.system),
          isLoading: true,
        ),
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.system),
          isLoading: false,
        ),
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.system),
          isLoading: true,
        ),
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.light),
          isLoading: false,
        ),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'emits new state when theme mode is changed to dark',
      setUp: () {
        when(
          () => mockGetThemePreferenceUseCase(),
        ).thenAnswer((_) async => const ThemePreference(mode: AppThemeMode.system));
        when(() => mockSetThemePreferenceUseCase(any())).thenAnswer((_) async => {});
      },
      build: () => ThemeBloc(
        getThemePreferenceUseCase: mockGetThemePreferenceUseCase,
        setThemePreferenceUseCase: mockSetThemePreferenceUseCase,
      ),
      act: (bloc) => bloc.add(const ThemeModeChanged(ThemePreference(mode: AppThemeMode.dark))),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.system),
          isLoading: true,
        ),
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.system),
          isLoading: false,
        ),
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.system),
          isLoading: true,
        ),
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.dark),
          isLoading: false,
        ),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'emits new state when theme mode is changed to system',
      setUp: () {
        when(
          () => mockGetThemePreferenceUseCase(),
        ).thenAnswer((_) async => const ThemePreference(mode: AppThemeMode.dark));
        when(() => mockSetThemePreferenceUseCase(any())).thenAnswer((_) async => {});
      },
      build: () => ThemeBloc(
        getThemePreferenceUseCase: mockGetThemePreferenceUseCase,
        setThemePreferenceUseCase: mockSetThemePreferenceUseCase,
      ),
      act: (bloc) => bloc.add(const ThemeModeChanged(ThemePreference(mode: AppThemeMode.system))),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.system),
          isLoading: true,
        ),
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.dark),
          isLoading: false,
        ),
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.dark),
          isLoading: true,
        ),
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.system),
          isLoading: false,
        ),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'handles exception when loading theme preference fails',
      setUp: () {
        when(() => mockGetThemePreferenceUseCase()).thenThrow(Exception('Error'));
      },
      build: () => ThemeBloc(
        getThemePreferenceUseCase: mockGetThemePreferenceUseCase,
        setThemePreferenceUseCase: mockSetThemePreferenceUseCase,
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.system),
          isLoading: true,
        ),
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.system),
          isLoading: false,
        ),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'handles exception when changing theme preference fails',
      setUp: () {
        when(
          () => mockGetThemePreferenceUseCase(),
        ).thenAnswer((_) async => const ThemePreference(mode: AppThemeMode.light));
        when(() => mockSetThemePreferenceUseCase(any())).thenThrow(Exception('Error'));
      },
      build: () => ThemeBloc(
        getThemePreferenceUseCase: mockGetThemePreferenceUseCase,
        setThemePreferenceUseCase: mockSetThemePreferenceUseCase,
      ),
      act: (bloc) => bloc.add(const ThemeModeChanged(ThemePreference(mode: AppThemeMode.dark))),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.system),
          isLoading: true,
        ),
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.light),
          isLoading: false,
        ),
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.light),
          isLoading: true,
        ),
        const ThemeState(
          themePreference: ThemePreference(mode: AppThemeMode.light),
          isLoading: false,
        ),
      ],
    );
  });
}
