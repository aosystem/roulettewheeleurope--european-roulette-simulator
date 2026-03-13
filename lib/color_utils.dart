import 'package:flutter/material.dart';

Color colorFromCode(String code) {
  switch (code) {
    case 'g':
      return const Color(0xFF00BB00);
    case 'k':
      return const Color(0xFF222222);
    case 'r':
      return const Color(0xFFD00000);
    default:
      return Colors.transparent;
  }
}

