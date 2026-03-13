import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:roulettewheeleurope/parse_locale_tag.dart';
import 'package:roulettewheeleurope/theme_mode_number.dart';
import 'package:roulettewheeleurope/theme_color.dart';
import 'package:roulettewheeleurope/model.dart';
import 'package:roulettewheeleurope/text_to_speech.dart';
import 'package:roulettewheeleurope/l10n/app_localizations.dart';
import 'package:roulettewheeleurope/setting_page.dart';
import 'package:roulettewheeleurope/wheel_view.dart';
import 'package:roulettewheeleurope/ad_manager.dart';
import 'package:roulettewheeleurope/ad_banner_widget.dart';
import 'package:roulettewheeleurope/color_utils.dart';
import 'package:roulettewheeleurope/main.dart';
import 'package:roulettewheeleurope/service_status.dart';
import 'package:roulettewheeleurope/loading_screen.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});
  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  AdManager? _adManager;
  final AudioPlayer _audio = AudioPlayer();
  //
  static const double _ballSizeRatio = 0.04;
  static const double _ballDistanceStart = 0.89;
  static const double _ballDistanceEnd = 0.535;
  //
  static const List<_RouletteSlot> _slots = [
    _RouletteSlot("0", "g"),
    _RouletteSlot("32", "r"),
    _RouletteSlot("15", "k"),
    _RouletteSlot("19", "r"),
    _RouletteSlot("4", "k"),
    _RouletteSlot("21", "r"),
    _RouletteSlot("2", "k"),
    _RouletteSlot("25", "r"),
    _RouletteSlot("17", "k"),
    _RouletteSlot("34", "r"),
    _RouletteSlot("6", "k"),
    _RouletteSlot("27", "r"),
    _RouletteSlot("13", "k"),
    _RouletteSlot("36", "r"),
    _RouletteSlot("11", "k"),
    _RouletteSlot("30", "r"),
    _RouletteSlot("8", "k"),
    _RouletteSlot("23", "r"),
    _RouletteSlot("10", "k"),
    _RouletteSlot("5", "r"),
    _RouletteSlot("24", "k"),
    _RouletteSlot("16", "r"),
    _RouletteSlot("33", "k"),
    _RouletteSlot("1", "r"),
    _RouletteSlot("20", "k"),
    _RouletteSlot("14", "r"),
    _RouletteSlot("31", "k"),
    _RouletteSlot("9", "r"),
    _RouletteSlot("22", "k"),
    _RouletteSlot("18", "r"),
    _RouletteSlot("29", "k"),
    _RouletteSlot("7", "r"),
    _RouletteSlot("28", "k"),
    _RouletteSlot("12", "r"),
    _RouletteSlot("35", "k"),
    _RouletteSlot("3", "r"),
    _RouletteSlot("26", "k"),
  ];
  // UI
  bool _startUiVisible = true;
  bool _settingUiVisible = true;
  // UI mirror state for Flutter-native wheel
  double _uiWheelAngle = 0;
  double _uiBallLeft = 0;
  double _uiBallTop = 0;
  double _uiBallSize = 0;
  bool _uiBallVisible = false;
  double _uiAlphaThree = 0;
  double _uiAlphaTwo = 0;
  double _uiAlphaOne = 0;
  double _uiAlphaNoMoreBets = 0;
  double _uiAlphaResult = 0;
  String _uiResultText = '';
  String _uiResultColor = '';
  final List<_HistoryItem> _history = <_HistoryItem>[];
  //
  late ThemeColor _themeColor;
  bool _isFirst = true;
  //ServiceStatus
  final bool _adsAvailable = ServiceStatus.adsEnabled;
  bool _ttsAvailable = ServiceStatus.ttsEnabled;

  // Wheel logic
  double _baseSize = 0;
  double _wheelAngle = 360;
  double _ballAngle = 0;
  double _wheelAngleStart = 0;
  bool _ballRotateFlag = false;
  int _ballTick = 0;
  double _adjustAngle = 0;
  double _ballDistanceRatio = _ballDistanceStart;
  bool _busy = false;
  Timer? _timer;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  void _initState() async {
    if (_adsAvailable) {
      _adManager = AdManager();
    }
    await _applyTtsPreferencesWithFallback();
    _initAudio();
    _startTicker();
    _scheduleServiceIssueMessage();
    setState(() {
      _isReady = true;
    });
  }

  Future<void> _applyTtsPreferencesWithFallback() async {
    if (!ServiceStatus.ttsEnabled) {
      _updateTtsAvailability(false);
      return;
    }
    try {
      await TextToSpeech.applyPreferences(
        Model.ttsVoiceId,
        Model.ttsVolume,
      ).timeout(const Duration(seconds: 5));
      _updateTtsAvailability(true);
    } on TimeoutException catch (error) {
      ServiceStatus.record(
        ServiceType.tts,
        'T001',
      );
      _updateTtsAvailability(false);
    } catch (error, stackTrace) {
      ServiceStatus.record(
        ServiceType.tts,
        'T002',
      );
      _updateTtsAvailability(false);
    }
  }

  void _updateTtsAvailability(bool value) {
    if (_ttsAvailable == value) {
      return;
    }
    if (!mounted) {
      _ttsAvailable = value;
      return;
    }
    setState(() {
      _ttsAvailable = value;
    });
  }

  void _scheduleServiceIssueMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(ServiceStatus.showIssuesMessage(context));
    });
  }

  @override
  void dispose() {
    _adManager?.dispose();
    _audio.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initAudio() async {
    await _audio.setReleaseMode(ReleaseMode.stop);
    await _audio.setVolume(Model.ttsVolume);
    try {
      await _audio.setSource(AssetSource('sound/kachi.wav'));
    } catch (_) {}
  }

  void _startTicker() {
    _timer = Timer.periodic(const Duration(milliseconds: 25), (_) {
      _wheelAngle -= 0.5;
      if (_wheelAngle < 0) {
        _wheelAngle = 359.5;
      }
      _setWheelRotation(_wheelAngle);
      if (_ballRotateFlag) {
        _adjustAngle += 0.5;
        _ballAngle += 5;
        if (_ballAngle >= 360) {
          _ballAngle = 0;
        }
        if (_ballTick > 0) {
          _ballTick -= 1;
          if (_ballTick == 500) {
            if (Model.countdown) {
              _showOverlay(three: 0.8);
              if (Model.ttsEnabled && Model.ttsVolume > 0.0) {
                _speak("3");
              }
            }
          }
          if (_ballTick == 450) {
            if (Model.countdown) {
              _showOverlay(three: 0.0, two: 0.8);
              if (Model.ttsEnabled && Model.ttsVolume > 0.0) {
                _speak("2");
              }
            }
          }
          if (_ballTick == 400) {
            if (Model.countdown) {
              _showOverlay(two: 0.0, one: 0.8);
              if (Model.ttsEnabled && Model.ttsVolume > 0.0) {
                _speak("1");
              }
            }
          }
          if (_ballTick == 350) {
            _showOverlay(one: 0.0);
            if (Model.showNoMoreBets) {
              _showOverlay(noMoreBets: 0.8);
            }
            if (Model.sayNoMoreBets) {
              _speak(AppLocalizations.of(context)?.noMoreBets ?? 'no more bets');
            }
          }
          if (_ballTick == 250) {
            _showOverlay(noMoreBets: 0.0);
            _ballTick -= (math.Random().nextDouble() * 100).toInt();
          }
          if (_ballTick < 5) {
            _ballDistanceRatio = (_ballDistanceStart + _ballDistanceEnd) / 2;
          }
          if (_ballTick < 1) {
            _ballDistanceRatio = _ballDistanceEnd;
          }
          if (_ballTick <= 0) {
            _ballRotateFlag = false;
            _setStartUiVisible(true);
            _resultNumber();
            _busy = false;
            _playPocketSound();
            if (Model.readOutResult) {
              Future.delayed(const Duration(milliseconds: 800), () {
                _speak(_speakTextForNumber(_uiResultText));
              });
            }
          }
        }
      }
      _ballPosition();
    });
  }

  void _speak(String text) {
    if (!_ttsAvailable) {
      return;
    }
    if (Model.ttsEnabled && Model.ttsVolume > 0.0) {
      TextToSpeech.speak(text);
    }
  }

  void _onStart() {
    if (_busy) {
      return;
    }
    _busy = true;
    _setStartUiVisible(false);
    _showOverlay(resultAlpha: 0.0);
    _ballAngle = 0;
    _setBallVisible(true);
    _ballDistanceRatio = _ballDistanceStart;
    _wheelAngleStart = _wheelAngle;
    _ballTick = (10 - Model.shortTime) * 100 + 260;
    _adjustAngle = 0;
    _ballRotateFlag = true;
  }

  void _resultNumber() {
    double angle = _ballAngle;
    angle = ((angle - _wheelAngleStart + _adjustAngle) / (360 / 37)).toInt() * (360 / 37) + (180 / 37);
    angle = 180 - angle + 0.5;
    angle += 3600;
    angle %= 360;
    int num = 37 - (angle / (360 / 37)).toInt();
    num %= 37;
    final slot = _slots[num];
    final resultNumber = slot.number;
    final resultColor = slot.color;
    _setResult(number: resultNumber, color: resultColor);
    if (Model.showResult) {
      _showOverlay(resultAlpha: 1.0);
    }
    _addHistory(resultNumber, resultColor);
  }

  String _speakTextForNumber(String number) {
    if (number == '00') {
      return 'double zero';
    }
    return number;
  }

  void _addHistory(String number, String color) {
    setState(() {
      _history.insert(0, _HistoryItem(number, color));
      if (_history.length > 20) {
        _history.removeLast();
      }
    });
  }

  Future<void> _playPocketSound() async {
    if (Model.soundVolume == 0.0) {
      return;
    }
    try {
      await _audio.setVolume(Model.soundVolume);
      await _audio.seek(Duration.zero);
      unawaited(_audio.resume());
    } catch (_) {
      try {
        await _audio.stop();
        await _audio.play(AssetSource('sound/kachi.wav'));
      } catch (_) {}
    }
  }

  void _ballPosition() {
    if (_baseSize <= 0) {
      return;
    }
    final ballSize = _baseSize * _ballSizeRatio;
    _setBallSize(ballSize.toInt());
    double angle = _ballAngle;
    if (!_ballRotateFlag) {
      angle = ((angle - _wheelAngleStart + _adjustAngle) / (360 / 37)).toInt() * (360 / 37) + (180 / 37);
      angle += _wheelAngle;
    }
    double x = (-math.sin(angle * (math.pi / 180)) * (_baseSize / 2));
    double y = (math.cos(angle * (math.pi / 180)) * (_baseSize / 2));
    x *= _ballDistanceRatio;
    y *= _ballDistanceRatio;
    x += _baseSize / 2.0 * 0.89;
    y += _baseSize / 2.0 * 0.89;
    x += ballSize * 0.9;
    y += ballSize * 0.9;
    _setBallPosition(x.toInt(), y.toInt());
  }

  Future<void> _setWheelRotation(double angle) async {
    setState(() {
      _uiWheelAngle = angle;
    });
  }

  Future<void> _setBallPosition(int x, int y) async {
    setState(() {
      _uiBallLeft = x.toDouble();
      _uiBallTop = y.toDouble();
    });
  }

  Future<void> _setBallSize(int sizePx) async {
    setState(() {
      _uiBallSize = sizePx.toDouble();
    });
  }

  Future<void> _setBallVisible(bool visible) async {
    setState(() {
      _uiBallVisible = visible;
    });
  }

  Future<void> _showOverlay({double? three, double? two, double? one, double? noMoreBets, double? resultAlpha}) async {
    setState(() {
      if (three != null) { _uiAlphaThree = three; }
      if (two != null) { _uiAlphaTwo = two; }
      if (one != null) { _uiAlphaOne = one; }
      if (noMoreBets != null) { _uiAlphaNoMoreBets = noMoreBets; }
      if (resultAlpha != null) { _uiAlphaResult = resultAlpha; }
    });
  }

  Future<void> _setResult({required String number, required String color}) async {
    setState(() {
      _uiResultText = number;
      _uiResultColor = color;
    });
  }

  void _setStartUiVisible(bool on) {
    setState(() {
      _startUiVisible = on;
      _settingUiVisible = on;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return LoadingScreen();
    }
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(themeNumber: Model.themeNumber, context: context);
    }
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _themeColor.mainBackColor,
      body: Stack(children:[
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_themeColor.mainBackColor, _themeColor.mainBack2Color, _themeColor.mainBack2Color, _themeColor.mainBackColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            image: DecorationImage(
              image: AssetImage('assets/image/tile.png'),
              repeat: ImageRepeat.repeat,
              opacity: 0.1,
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Row(children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: IconButton(
                    onPressed: _settingUiVisible ? _onClickSetting : null,
                    tooltip: l.setting,
                    icon: Icon(Icons.settings, color: Colors.white.withValues(alpha: _settingUiVisible ? 0.85 : 0)),
                  ),
                ),
              ]),
              const SizedBox(height: 5),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final paddingH = 10.0;
                    final width = constraints.maxWidth - paddingH * 2;
                    _baseSize = width;
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: Center(
                                child: WheelFlutterView(
                                  size: width,
                                  wheelAngleDeg: _uiWheelAngle,
                                  ballVisible: _uiBallVisible,
                                  ballLeft: _uiBallLeft,
                                  ballTop: _uiBallTop,
                                  ballSize: _uiBallSize,
                                  alphaThree: _uiAlphaThree,
                                  alphaTwo: _uiAlphaTwo,
                                  alphaOne: _uiAlphaOne,
                                  alphaNoMoreBets: _uiAlphaNoMoreBets,
                                  alphaResult: _uiAlphaResult,
                                  resultText: _uiResultText,
                                  resultColor: _uiResultColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Stack(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: 60,
                                    height: 200,
                                    child: _buildHistoryList(),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    opacity: _startUiVisible ? 1.0 : 0.0,
                                    child: Opacity(
                                      opacity: _busy ? 0.4 : 1.0,
                                      child: ElevatedButton(
                                        onPressed: _busy ? null : _onStart,
                                        style: ElevatedButton.styleFrom(
                                          shape: const CircleBorder(),
                                          fixedSize: const Size(180, 180),
                                          backgroundColor: _themeColor.mainButtonBackColor,
                                          elevation: 0,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(l.start,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: _themeColor.mainButtonForeColor, fontSize: 28),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 200),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          )
        ),
      ]),
      bottomNavigationBar: _adsAvailable && _adManager != null
          ? AdBannerWidget(adManager: _adManager!)
          : null,
    );
  }

  void _onClickSetting() async {
    final updatedSettings = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingPage(),
      ),
    );
    if (updatedSettings != null) {
      if (mounted) {
        await _applyTtsPreferencesWithFallback();
        _scheduleServiceIssueMessage();
        //
        final mainState = context.findAncestorStateOfType<MainAppState>();
        if (mainState != null) {
          mainState
            ..locale = parseLocaleTag(Model.languageCode)
            ..themeMode = ThemeModeNumber.numberToThemeMode(Model.themeNumber)
            ..setState(() {});
          setState(() {
            _isFirst = true;
          });
        }
      }
    }
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return SizedBox.shrink();
    }
    if (Model.showHistory == false) {
      return SizedBox.shrink();
    }
    return ListView.separated(
      reverse: false,
      itemCount: _history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 1),
      itemBuilder: (context, index) {
        final item = _history[index];
        return Container(
          height: 19,
          decoration: BoxDecoration(
            color: colorFromCode(item.color),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            item.number,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
      },
    );
  }

}

class _HistoryItem {
  final String number;
  final String color;
  _HistoryItem(this.number, this.color);
}

class _RouletteSlot {
  final String number;
  final String color;
  const _RouletteSlot(this.number, this.color);
}
