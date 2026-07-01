import 'package:collab_tasks/features/settings/domain/models/theme_preference.dart';
import 'package:equatable/equatable.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class ThemeInitialized extends ThemeEvent {
  const ThemeInitialized();
}

class ThemeModeChanged extends ThemeEvent {
  final ThemePreference themePreference;

  const ThemeModeChanged(this.themePreference);

  @override
  List<Object?> get props => [themePreference];
}
