import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:roulettewheeleurope/color_utils.dart';

class WheelFlutterView extends StatelessWidget {
  final double size;
  final double wheelAngleDeg;
  final bool ballVisible;
  final double ballLeft;
  final double ballTop;
  final double ballSize;
  final double alphaThree;
  final double alphaTwo;
  final double alphaOne;
  final double alphaNoMoreBets;
  final double alphaResult;
  final String resultText;
  final String resultColor;

  const WheelFlutterView({
    super.key,
    required this.size,
    required this.wheelAngleDeg,
    required this.ballVisible,
    required this.ballLeft,
    required this.ballTop,
    required this.ballSize,
    required this.alphaThree,
    required this.alphaTwo,
    required this.alphaOne,
    required this.alphaNoMoreBets,
    required this.alphaResult,
    required this.resultText,
    required this.resultColor,
  });

  @override
  Widget build(BuildContext context) {
    final wheelAngleRad = wheelAngleDeg * (math.pi / 180.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/image/roulettewheel_base.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.low,
            ),
          ),
          Positioned.fill(
            child: Transform.rotate(
              angle: wheelAngleRad,
              child: Image.asset(
                'assets/image/roulettewheel_top.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.low,
              ),
            ),
          ),
          Positioned(
            left: ballLeft,
            top: ballTop,
            child: Opacity(
              opacity: ballVisible ? 1.0 : 0.0,
              child: Image.asset(
                'assets/image/ball.png',
                width: ballSize,
                height: ballSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.low,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedOpacity(
                opacity: alphaThree.clamp(0.0, 1.0),
                duration: const Duration(milliseconds: 300),
                child: Image.asset('assets/image/three.png', fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedOpacity(
                opacity: alphaTwo.clamp(0.0, 1.0),
                duration: const Duration(milliseconds: 300),
                child: Image.asset('assets/image/two.png', fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedOpacity(
                opacity: alphaOne.clamp(0.0, 1.0),
                duration: const Duration(milliseconds: 300),
                child: Image.asset('assets/image/one.png', fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedOpacity(
                opacity: alphaNoMoreBets.clamp(0.0, 1.0),
                duration: const Duration(milliseconds: 300),
                child: Image.asset('assets/image/nomorebets.png', fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: alphaResult.clamp(0.0, 1.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorFromCode(resultColor),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Text(
                      resultText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
