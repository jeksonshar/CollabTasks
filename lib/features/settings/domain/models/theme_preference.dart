import 'package:equatable/equatable.dart';

enum AppThemeMode { light, dark, system }

class ThemePreference extends Equatable {
  final AppThemeMode mode;

  const ThemePreference({required this.mode});

  ThemePreference copyWith({AppThemeMode? mode}) {
    return ThemePreference(mode: mode ?? this.mode);
  }

  String toMap() => mode.name;

  static ThemePreference fromMap(String? value) {
    if (value == null || value.isEmpty) {
      return const ThemePreference(mode: AppThemeMode.system);
    }
    try {
      return ThemePreference(mode: AppThemeMode.values.firstWhere((e) => e.name == value));
    } catch (_) {
      return const ThemePreference(mode: AppThemeMode.system);
    }
  }

  @override
  List<Object?> get props => [mode];
}
