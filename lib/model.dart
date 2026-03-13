import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:roulettewheeleurope/l10n/app_localizations.dart';

class Model {
  Model._();

  static const String _prefShortTime = "shortTime";
  static const String _prefShowNoMoreBets = "showNoMoreBets";
  static const String _prefSayNoMoreBets = "sayNoMoreBets";
  static const String _prefShowResult = "showResult";
  static const String _prefReadOutResult = "readOutResult";
  static const String _prefShowHistory = "showHistory";
  static const String _prefCountdown = "countdown";
  static const String _prefSoundVolume = "soundVolume";
  static const String _prefTtsEnabled = "ttsEnabled";
  static const String _prefTtsVolume = "ttsVolume";
  static const String _prefTtsVoiceId = "ttsVoiceId";
  static const String _prefSchemeColor = 'schemeColor';
  static const String _prefThemeNumber = "themeNumber";
  static const String _prefLanguageCode = "languageCode";

  static bool _ready = false;
  static int _shortTime = 0;
  static bool _showNoMoreBets = true;
  static bool _sayNoMoreBets = true;
  static bool _showResult = true;
  static bool _readOutResult = true;
  static bool _showHistory = true;
  static bool _countdown = false;
  static double _soundVolume = 0.5;
  static bool _ttsEnabled = true;
  static double _ttsVolume = 1.0;
  static String _ttsVoiceId = '';
  static int _schemeColor = 120;
  static int _themeNumber = 0;
  static String _languageCode = '';

  static int get shortTime => _shortTime;
  static bool get showNoMoreBets => _showNoMoreBets;
  static bool get sayNoMoreBets => _sayNoMoreBets;
  static bool get showResult => _showResult;
  static bool get readOutResult => _readOutResult;
  static bool get showHistory => _showHistory;
  static bool get countdown => _countdown;
  static double get soundVolume => _soundVolume;
  static bool get ttsEnabled => _ttsEnabled;
  static double get ttsVolume => _ttsVolume;
  static String get ttsVoiceId => _ttsVoiceId;
  static int get schemeColor => _schemeColor;
  static int get themeNumber => _themeNumber;
  static String get languageCode => _languageCode;

  static Future<void> ensureReady() async {
    if (_ready) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    //
    _shortTime = (prefs.getInt(_prefShortTime) ?? 0).clamp(0, 10);
    _showNoMoreBets = prefs.getBool(_prefShowNoMoreBets) ?? true;
    _sayNoMoreBets = prefs.getBool(_prefSayNoMoreBets) ?? true;
    _showResult = prefs.getBool(_prefShowResult) ?? true;
    _readOutResult = prefs.getBool(_prefReadOutResult) ?? true;
    _showHistory = prefs.getBool(_prefShowHistory) ?? true;
    _countdown = prefs.getBool(_prefCountdown) ?? false;
    _soundVolume = (prefs.getDouble(_prefSoundVolume) ?? 0.5).clamp(0.0, 1.0);
    _ttsEnabled = prefs.getBool(_prefTtsEnabled) ?? true;
    _ttsVolume = (prefs.getDouble(_prefTtsVolume) ?? 1.0).clamp(0.0, 1.0);
    _ttsVoiceId = prefs.getString(_prefTtsVoiceId) ?? '';
    _schemeColor = (prefs.getInt(_prefSchemeColor) ?? 120).clamp(0, 360);
    _themeNumber = (prefs.getInt(_prefThemeNumber) ?? 0).clamp(0, 2);
    _languageCode = prefs.getString(_prefLanguageCode) ?? ui.PlatformDispatcher.instance.locale.languageCode;
    _languageCode = _resolveLanguageCode(_languageCode);
    _ready = true;
  }

  static String _resolveLanguageCode(String code) {
    final supported = AppLocalizations.supportedLocales;
    if (supported.any((l) => l.languageCode == code)) {
      return code;
    } else {
      return '';
    }
  }

  static Future<void> setShortTime(int value) async {
    _shortTime = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefShortTime, value);
  }

  static Future<void> setSayNoMoreBets(bool value) async {
    _sayNoMoreBets = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSayNoMoreBets, value);
  }

  static Future<void> setShowNoMoreBets(bool value) async {
    _showNoMoreBets = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefShowNoMoreBets, value);
  }

  static Future<void> setShowResult(bool value) async {
    _showResult = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefShowResult, value);
  }

  static Future<void> setReadOutResult(bool value) async {
    _readOutResult = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefReadOutResult, value);
  }

  static Future<void> setShowHistory(bool value) async {
    _showHistory = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefShowHistory, value);
  }

  static Future<void> setCountdown(bool value) async {
    _countdown = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefCountdown, value);
  }

  static Future<void> setSoundVolume(double value) async {
    _soundVolume = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefSoundVolume, value);
  }

  static Future<void> setTtsEnabled(bool value) async {
    _ttsEnabled = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefTtsEnabled, value);
  }

  static Future<void> setTtsVolume(double value) async {
    _ttsVolume = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefTtsVolume, value);
  }

  static Future<void> setTtsVoiceId(String value) async {
    _ttsVoiceId = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTtsVoiceId, value);
  }

  static Future<void> setSchemeColor(int value) async {
    _schemeColor = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefSchemeColor, value);
  }

  static Future<void> setThemeNumber(int value) async {
    _themeNumber = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefThemeNumber, value);
  }

  static Future<void> setLanguageCode(String value) async {
    _languageCode = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLanguageCode, value);
  }

}
