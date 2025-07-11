import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageProvider extends ChangeNotifier {
  Locale _appLocale = const Locale('uz'); // Дефолт ўзбек тили

  Locale get appLocale => _appLocale;

  AppLanguageProvider() {
    _fetchLocale();
  }

  Future<void> _fetchLocale() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('language_code')) {
      final String? langCode = prefs.getString('language_code');
      if (langCode != null) {
        _appLocale = Locale(langCode);
        notifyListeners();
      }
    }
  }

  Future<void> changeLanguage(Locale type) async {
    final prefs = await SharedPreferences.getInstance();
    if (_appLocale == type) {
      return;
    }
    if (type == const Locale('uz')) {
      _appLocale = const Locale('uz');
      await prefs.setString('language_code', 'uz');
    } else if (type == const Locale('ru')) {
      _appLocale = const Locale('ru');
      await prefs.setString('language_code', 'ru');
    } else {
      _appLocale = const Locale('en');
      await prefs.setString('language_code', 'en');
    }
    notifyListeners();
  }
}
