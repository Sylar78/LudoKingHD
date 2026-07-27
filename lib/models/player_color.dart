import 'package:flutter/material.dart';

enum PlayerColor { red, blue, green, yellow }

extension PlayerColorExtension on PlayerColor {
  Color get color {
    switch (this) {
      case PlayerColor.red:
        return const Color(0xFFE53935);
      case PlayerColor.blue:
        return const Color(0xFF1E88E5);
      case PlayerColor.green:
        return const Color(0xFF43A047);
      case PlayerColor.yellow:
        return const Color(0xFFFDD835);
    }
  }

  Color get lightColor {
    switch (this) {
      case PlayerColor.red:
        return const Color(0xFFFFCDD2);
      case PlayerColor.blue:
        return const Color(0xFFBBDEFB);
      case PlayerColor.green:
        return const Color(0xFFC8E6C9);
      case PlayerColor.yellow:
        return const Color(0xFFFFF9C4);
    }
  }

  Color get darkColor {
    switch (this) {
      case PlayerColor.red:
        return const Color(0xFFB71C1C);
      case PlayerColor.blue:
        return const Color(0xFF0D47A1);
      case PlayerColor.green:
        return const Color(0xFF1B5E20);
      case PlayerColor.yellow:
        return const Color(0xFFF57F17);
    }
  }

  String get name {
    switch (this) {
      case PlayerColor.red:
        return 'Rouge';
      case PlayerColor.blue:
        return 'Bleu';
      case PlayerColor.green:
        return 'Vert';
      case PlayerColor.yellow:
        return 'Jaune';
    }
  }

  /// Starting position on the outer path (index 0-51)
  int get startPosition {
    switch (this) {
      case PlayerColor.red:
        return 0;
      case PlayerColor.blue:
        return 13;
      case PlayerColor.green:
        return 26;
      case PlayerColor.yellow:
        return 39;
    }
  }

  /// Safe zone entry: the last outer-path position before entering home column
  int get homeEntryPosition {
    switch (this) {
      case PlayerColor.red:
        return 51;
      case PlayerColor.blue:
        return 12;
      case PlayerColor.green:
        return 25;
      case PlayerColor.yellow:
        return 38;
    }
  }
}
