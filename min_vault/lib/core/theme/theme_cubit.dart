import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:min_vault/core/theme/app_theme.dart';

class ThemeCubit extends Cubit<bool> {
  ThemeCubit({required SharedPreferences prefs})
    : _prefs = prefs,
      super(prefs.getBool(_key) ?? false) {
    AppTheme.applyBrightness(state ? Brightness.dark : Brightness.light);
  }

  final SharedPreferences _prefs;
  static const _key = 'settings_dark_mode';

  Future<void> toggle(bool isDark) async {
    AppTheme.applyBrightness(isDark ? Brightness.dark : Brightness.light);
    await _prefs.setBool(_key, isDark);
    emit(isDark);
  }
}
