import 'package:collab_tasks/features/settings/domain/models/theme_preference.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/get_theme_preference_use_case.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/set_theme_preference_use_case.dart';
import 'package:collab_tasks/features/settings/ui/blocs/theme_bloc/theme_event.dart';
import 'package:collab_tasks/features/settings/ui/blocs/theme_bloc/theme_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final GetThemePreferenceUseCase _getThemePreferenceUseCase;
  final SetThemePreferenceUseCase _setThemePreferenceUseCase;

  ThemeBloc({
    required GetThemePreferenceUseCase getThemePreferenceUseCase,
    required SetThemePreferenceUseCase setThemePreferenceUseCase,
  }) : _getThemePreferenceUseCase = getThemePreferenceUseCase,
       _setThemePreferenceUseCase = setThemePreferenceUseCase,
       super(const ThemeState(themePreference: ThemePreference(mode: AppThemeMode.system))) {
    on<ThemeInitialized>(_onThemeInitialized);
    on<ThemeModeChanged>(_onThemeModeChanged);
    _loadInitialTheme();
  }

  Future<void> _onThemeInitialized(ThemeInitialized event, Emitter<ThemeState> emit) async {
    try {
      emit(state.copyWith(isLoading: true));
      final themePreference = await _getThemePreferenceUseCase();
      emit(state.copyWith(themePreference: themePreference, isLoading: false));
    } catch (e, stackTrace) {
      debugPrint('ThemeBloc - Failed to load theme preference: $e\n$stackTrace');
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onThemeModeChanged(ThemeModeChanged event, Emitter<ThemeState> emit) async {
    try {
      emit(state.copyWith(isLoading: true));
      await _setThemePreferenceUseCase(event.themePreference);
      emit(state.copyWith(themePreference: event.themePreference, isLoading: false));
    } catch (e, stackTrace) {
      debugPrint('ThemeBloc - Failed to change theme: $e\n$stackTrace');
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _loadInitialTheme() async {
    add(const ThemeInitialized());
  }
}
