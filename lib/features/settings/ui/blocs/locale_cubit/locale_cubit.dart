import 'package:collab_tasks/features/settings/domain/use_cases/get_saved_language_use_case.dart';
import 'package:collab_tasks/features/settings/domain/use_cases/set_saved_language_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LocaleCubit extends Cubit<Locale?> {
  final GetSavedLanguageUseCase _getSavedLanguageUseCase;
  final SetSavedLanguageUseCase _setSavedLanguageUseCase;

  LocaleCubit({
    required GetSavedLanguageUseCase getSavedLanguageUseCase,
    required SetSavedLanguageUseCase setSavedLanguageUseCase,
  }) : _getSavedLanguageUseCase = getSavedLanguageUseCase,
       _setSavedLanguageUseCase = setSavedLanguageUseCase,
       super(null) {
    _loadSavedLocale();
  }

  Future<void> changeLocale(String languageCode) async {
    emit(Locale(languageCode));
    await _setSavedLanguageUseCase(languageCode);
  }

  Future<void> _loadSavedLocale() async {
    final savedLanguageCode = await _getSavedLanguageUseCase();
    if (savedLanguageCode == null || savedLanguageCode.isEmpty) {
      return;
    }
    emit(Locale(savedLanguageCode));
  }
}
