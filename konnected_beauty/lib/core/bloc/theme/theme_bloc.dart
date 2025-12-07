import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class ThemeEvent {}

class ChangeTheme extends ThemeEvent {
  final Brightness brightness;
  ChangeTheme(this.brightness);
}

class LoadTheme extends ThemeEvent {}

// States
abstract class ThemeState {
  final Brightness brightness;
  const ThemeState(this.brightness);
}

class ThemeInitial extends ThemeState {
  const ThemeInitial() : super(Brightness.dark);
}

class ThemeLoaded extends ThemeState {
  const ThemeLoaded(super.brightness);
}

class ThemeError extends ThemeState {
  final String message;
  const ThemeError(super.brightness, this.message);
}

// Bloc
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _themeKey = 'selected_theme';

  ThemeBloc({Brightness? initialBrightness})
      : super(initialBrightness != null
            ? ThemeLoaded(initialBrightness)
            : const ThemeInitial()) {
    on<LoadTheme>(_onLoadTheme);
    on<ChangeTheme>(_onChangeTheme);
  }

  Future<void> _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themeKey) ?? true; // Default to dark
      final brightness = isDark ? Brightness.dark : Brightness.light;
      emit(ThemeLoaded(brightness));
    } catch (e) {
      emit(ThemeError(Brightness.dark, e.toString()));
    }
  }

  Future<void> _onChangeTheme(
      ChangeTheme event, Emitter<ThemeState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, event.brightness == Brightness.dark);
      emit(ThemeLoaded(event.brightness));
    } catch (e) {
      emit(ThemeError(state.brightness, e.toString()));
    }
  }
}
