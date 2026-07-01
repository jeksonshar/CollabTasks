import 'package:collab_tasks/features/settings/domain/models/theme_preference.dart';
import 'package:equatable/equatable.dart';

class ThemeState extends Equatable {
  final ThemePreference themePreference;
  final bool isLoading;

  const ThemeState({required this.themePreference, this.isLoading = false});

  ThemeState copyWith({ThemePreference? themePreference, bool? isLoading}) {
    return ThemeState(
      themePreference: themePreference ?? this.themePreference,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [themePreference, isLoading];
}
