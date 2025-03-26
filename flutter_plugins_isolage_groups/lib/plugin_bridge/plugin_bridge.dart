import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:isolate';

import 'package:path/path.dart' as path;

import 'bridge_message.dart';
import 'plugin_message.dart';

final class RunPluginsData {
  Isolate? isolate;
  ReceivePort? receivePort;
  SendPort? sendPort;

  RunPluginsData({
    required this.isolate,
    required this.receivePort,
    this.sendPort,
  });

  void dispose() {
    isolate?.kill();
    receivePort?.close();
  }
}

final class PluginBridge {
  static Map<String, RunPluginsData> _plugins = {};

  RunPluginsData? _currentRunPlugin;
  List<FileSystemEntity>? _plugInDir;
  StreamSubscription? _subscription;
  final String _pluginsDir;
  final Stdin _input;
  final Stdout _output;
  File? _logFile;
  IOSink? _logFileSink;

  PluginBridge(
      {required Stdin input,
      required Stdout output,
      required String pluginsDir})
      : _output = output,
        _input = input,
        _pluginsDir = pluginsDir {
    _logFile =
        File(path.join(pluginsDir, '${_getDataTime()}--flutter_bridge.log'));
    _logFileSink = _logFile?.openWrite(mode: FileMode.append);
    _subscription = _input.transform(utf8.decoder).listen(_listen);
    _logFileSink?.writeln('${_getDataTime()} Start listen path: $pluginsDir');
  }

  void _listen(String data) async {
    var message = BridgeMessage.fromJson(jsonDecode(data));
    _logFileSink?.writeln('${_getDataTime()} $data');
    switch (message) {
      case StopBridgeMessage():
        _output.write(jsonEncode(StopBridgeMessage().toJson()));
        _subscription?.cancel();
        _plugins.forEach((key, value) {
          value.dispose();
        });
        exit(0);
      case UpdateBridgeMessage():
        _updateHandle();
      case LoadBridgeMessage(pluginFile: String pluginFile):
        _loadHandle(pluginFile);
      case UnloadBridgeMessage():
        _unloadHandle();
      case RequestBridgeMessage(firstValue: int a, secondValue: int b):
        _requestHandle(a, b);
      default:
      // Oooopsss
    }
  }

  void _loadHandle(String pluginFile) async {
    _logFileSink?.writeln('${_getDataTime()} $pluginFile Start load');
    if (_plugins.containsKey(pluginFile)) {
      return;
    }

    var receivePort = ReceivePort();
    var pathToPlugin = _plugInDir!.firstWhere(
      (element) => path.basename(element.path) == pluginFile,
    );

    _plugins[pluginFile] = RunPluginsData(
      isolate: await Isolate.spawnUri(
          Uri.file(pathToPlugin.path), [], receivePort.sendPort),
      receivePort: receivePort,
    );
    _currentRunPlugin = _plugins[pluginFile];

    receivePort.listen((data) {
      var message = PluginMessage.fromJson(data);
      switch (message) {
        case StopPluginMessage():
          _currentRunPlugin?.dispose();
          _plugins.remove(pluginFile);
          _currentRunPlugin = null;
          _output.write(jsonEncode(
            UnloadBridgeMessage('').toJson(),
          ));
        case ResponsePluginMessage(result: int result):
          _output.write(jsonEncode(
            ResponseBridgeMessage(result).toJson(),
          ));
        case StartPluginMessage(sender: var sender, hello: var hello):
          _currentRunPlugin?.sendPort = sender;
          _output.write(jsonEncode(
            LoadBridgeMessage(pluginFile).toJson(),
          ));
        default:
        // Oooopsss
      }
    });

    _logFileSink?.writeln('${_getDataTime()} $pluginFile Finish load');
  }

  void _requestHandle(int a, int b) async {
    if (_currentRunPlugin != null) {
      _currentRunPlugin?.sendPort?.send(RequestPluginMessage(a, b).toJson());
    }
  }

  void _unloadHandle() async {
    if (_currentRunPlugin != null) {
      _currentRunPlugin?.sendPort?.send(StopPluginMessage().toJson());
    }
  }

  String _getDataTime() {
    return '${DateTime.now()}'.replaceAll(':', '-');
  }

  void _updateHandle() async {
    _logFileSink?.writeln('${_getDataTime()} Start update');
    _plugInDir = Directory(_pluginsDir)
        .listSync()
        .where((element) => element.path.endsWith('.aot'))
        .toList();
    List<String> plugNames = [];
    _plugInDir?.forEach((element) {
      plugNames.add(path.basename(element.path));
    });
    _output.write(jsonEncode(
      UpdateBridgeMessage(plugNames).toJson(),
    ));
    _logFileSink?.writeln('${_getDataTime()} Finish update');
  }
}

void main(List<String> args) async {
  // Release
  var pluginBridge = PluginBridge(
    pluginsDir: args[0],
    // pluginsDir: path.join(Directory.current.path,),
    input: stdin,
    output: stdout,
  );
  pluginBridge._updateHandle();
}
