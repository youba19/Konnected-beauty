import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class LanguageEvent {}

class ChangeLanguage extends LanguageEvent {
  final Locale locale;
  ChangeLanguage(this.locale);
}

class LoadLanguage extends LanguageEvent {}

// States
abstract class LanguageState {
  final Locale locale;
  const LanguageState(this.locale);
}

class LanguageInitial extends LanguageState {
  const LanguageInitial() : super(const Locale('fr'));
}

class LanguageLoaded extends LanguageState {
  const LanguageLoaded(Locale locale) : super(locale);
}

class LanguageError extends LanguageState {
  final String message;
  const LanguageError(Locale locale, this.message) : super(locale);
}

// Bloc
class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  static const String _languageKey = 'selected_language';

  LanguageBloc() : super(const LanguageInitial()) {
    on<LoadLanguage>(_onLoadLanguage);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  Future<void> _onLoadLanguage(
      LoadLanguage event, Emitter<LanguageState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'fr';
      final locale = Locale(languageCode);
      emit(LanguageLoaded(locale));
    } catch (e) {
      emit(const LanguageError(Locale('fr'), 'Failed to load language'));
    }
  }

  Future<void> _onChangeLanguage(
      ChangeLanguage event, Emitter<LanguageState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, event.locale.languageCode);
      emit(LanguageLoaded(event.locale));
    } catch (e) {
      emit(LanguageError(event.locale, 'Failed to change language'));
    }
  }
}
