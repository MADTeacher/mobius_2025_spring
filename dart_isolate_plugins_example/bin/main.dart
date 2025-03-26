import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;
import 'package:dart_isolate_plugins_example/ansi_cli_helper.dart';

import 'message.dart';

void main(List<String> arguments) async {
  MainMenu(helper: AnsiCliHelper()).run();
}

enum AppState {
  none,
  loadPlugin,
  prosessing,
  exit,
}

class MainMenu {
  List<FileSystemEntity> _filesForLoad = [];
  final AnsiCliHelper _helper;
  FileSystemEntity? _loadedFile;
  var state = AppState.none;
  bool _startProcessing = false;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  Isolate? _plugin;

  MainMenu({
    required AnsiCliHelper helper,
  }) : _helper = helper {
    _helper.reset();
  }

  void _updateAppState(AppState newState) async {
    if (newState == AppState.loadPlugin) {
      _loadedFile = null;
      var currentPath = path.join(
        Directory.current.path,
        'bin',
        'isolate_groups',
      );

      // получить список только aot-файлов
      _filesForLoad = Directory(currentPath)
          .listSync()
          .where((element) => element.path.endsWith('.aot'))
          .toList();
    }
    state = newState;
  }

  void _loadHandler() {
    do {
      _helper.clear();
      _helper.setTextColor(AnsiTextColors.yellow);
      _helper.writeLine('========================');
      _helper.writeLine('~~~   Select file    ~~~');
      _helper.writeLine('========================');
      for (var i = 0; i < _filesForLoad.length; i++) {
        _helper.writeLine('$i. ${_filesForLoad[i].path}');
      }
      _helper.setTextColor(AnsiTextColors.red);
      _helper.writeLine('${_filesForLoad.length}. Back');
      _helper.setTextColor(AnsiTextColors.yellow);
      _helper.writeLine('========================');
      _helper.write('Select: ');
      var val = int.tryParse(stdin.readLineSync()!);
      if (val != null) {
        if (val >= _filesForLoad.length) {
          _updateAppState(AppState.none);
          return;
        } else if (val < _filesForLoad.length && val >= 0) {
          _loadedFile = _filesForLoad[val];
          _updateAppState(AppState.prosessing);
          return;
        }
      }
    } while (true);
  }

  static const List<String> _menu = [
    '1. Load plugin',
    '2. Processing',
    '3. Exit',
  ];

  void printMenu() {
    do {
      _helper.clear();
      _helper.setTextColor(AnsiTextColors.yellow);
      _helper.writeLine('========================');
      _helper.writeLine('~~~   Mobius Conf    ~~~');
      _helper.writeLine('========================');
      for (var i = 0; i < _menu.length; i++) {
        _helper.writeLine(_menu[i]);
      }
      _helper.setTextColor(AnsiTextColors.yellow);
      _helper.writeLine('========================');
      _helper.write('Select: ');
      _helper.setTextColor(AnsiTextColors.white);
      var val = int.tryParse(stdin.readLineSync()!);
      if (val != null) {
        if (val <= _menu.length && val >= 0) {
          _updateAppState(AppState.values[val]);
          return;
        }
      }
    } while (true);
  }

  void run() async {
    while (state != AppState.exit) {
      switch (state) {
        case AppState.none:
          printMenu();
        case AppState.loadPlugin:
          _loadHandler();
          if (_loadedFile != null) {
            _receivePort = ReceivePort();
            _plugin = await Isolate.spawnUri(
              Uri.file(_loadedFile!.path),
              [],
              _receivePort!.sendPort,
            );

            _receivePort!.listen((data) async {
              var message = Message.fromJson(data);
              switch (message) {
                case StopMessage():
                  print('Isolate group closed');
                  _receivePort!.close();
                  _receivePort = null;
                  _sendPort = null;
                  _plugin!.kill();
                  _plugin = null;
                  _startProcessing = false;
                case ResponseMessage(
                    result: int a,
                  ):
                  print('Result $a');
                  await Future.delayed(const Duration(milliseconds: 5000));
                  _sendPort?.send(StopMessage().toJson());

                case StartMessage(sender: var sender, hello: var hello):
                  _sendPort = sender;
                  print(hello);
                case RequestMessage():
                  print('Message is not supported');
              }
            });
            _updateAppState(AppState.prosessing);
          }
        case AppState.prosessing:
          if (_plugin == null) {
            print('Plugin is not loaded');
            await Future.delayed(const Duration(milliseconds: 3000));
            _updateAppState(AppState.loadPlugin);
            continue;
          }

          if (!_startProcessing) {
            _helper.clear();
            print('Input two numbers: ');
            var a = int.tryParse(stdin.readLineSync() ?? '0');
            var b = int.tryParse(stdin.readLineSync() ?? '0');
            if (a == null || b == null) {
              _helper.clear();
              continue;
            }
            _sendPort?.send(RequestMessage(a, b).toJson());
            _startProcessing = true;
          }

        default:
          break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
