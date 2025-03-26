import 'dart:io';

import 'src/ansi_background_colors.dart';
import 'src/ansi_text_colors.dart';

export 'src/ansi_background_colors.dart';
export 'src/ansi_text_colors.dart';

final class AnsiCliHelper {
  static AnsiCliHelper? _instance;
  bool _isHideCursor = false;

  AnsiCliHelper._();

  factory AnsiCliHelper() {
    return _instance ??= AnsiCliHelper._();
  }

  bool get isHideCursor => _isHideCursor;

  void showCursor() {
    if (_isHideCursor) {
      stdout.write('\u001b[?25h'); // Включение курсора
      _isHideCursor = false;
    }
  }

  void hideCursor() {
    if (!_isHideCursor) {
      stdout.write('\u001b[?25l'); // Выключение курсора
      _isHideCursor = true;
    }
  }

  void clear() {
    stdout.write('\u001b[2J\u001b[0;0H'); // Очистка экрана
  }

  void reset() {
    setTextColor(AnsiTextColors.white);
    setBackgroundColor(AnsiBackgroundColors.black);
    clear();
    showCursor();
  }

  void write(String text) {
    stdout.write(text);
  }

  void writeLine(String text) {
    stdout.writeln(text);
  }

  void setTextColor(AnsiTextColors color) {
    stdout.write(color.ansiText);
  }

  void setBackgroundColor(AnsiBackgroundColors color) {
    stdout.write(color.ansiText);
  }

  void gotoxy(int x, int y) {
    if (x < 0 || y < 0) {
      return;
    }
    stdout.write('\u001b[$y;${x}H');
  }
}
