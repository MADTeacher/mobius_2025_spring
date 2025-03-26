import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'plugin_bridge/bridge_message.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter isolation-maniac example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? result;
  Process? pluginBridge;
  String? pathToPluginBridge;
  String? pathToPlugins;
  StreamSubscription? subscription;
  List<String> plugins = [];
  int selectedPlugin = -1;
  bool isRunningPlugin = false;
  final firstNumberController = TextEditingController();
  final secondNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    if (isRunningPlugin) {
      pluginBridge?.stdin.write(
        jsonEncode(
          UnloadBridgeMessage('').toJson(),
        ),
      );
    }
    pluginBridge?.stdin.write(jsonEncode(StopBridgeMessage().toJson()));
    subscription?.cancel();
    pluginBridge?.kill();
  }

  void _setPathToPluginBridge() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe'],
    );
    setState(() {
      pathToPluginBridge = result?.files.single.path;
    });
  }

  void _updateHandle() async {
    if (isRunningPlugin) {
      pluginBridge?.stdin.write(
        jsonEncode(
          UnloadBridgeMessage('').toJson(),
        ),
      );
    } else {
      pluginBridge?.stdin.write(jsonEncode(
        UpdateBridgeMessage([]).toJson(),
      ));
    }
  }

  void _runPluginBridge() async {
    if (pathToPluginBridge != null &&
        pathToPlugins != null &&
        pluginBridge == null) {
      pluginBridge = await Process.start(
        pathToPluginBridge!,
        [pathToPlugins!],
        runInShell: true,
      );

      subscription =
          pluginBridge?.stdout.transform(utf8.decoder).listen((String event) {
        var tmp = event.trim();
        if (tmp.isNotEmpty) {
          var message = BridgeMessage.fromJson(jsonDecode(tmp));
          switch (message) {
            case StopBridgeMessage():
              setState(() {
                subscription?.cancel();
                pluginBridge?.kill();
                pluginBridge = null;
                plugins = [];
                selectedPlugin = -1;
                isRunningPlugin = false;
              });
            case UpdateBridgeMessage(plugins: var plugins):
              setState(() {
                selectedPlugin = -1;
                isRunningPlugin = false;
                this.plugins = plugins;
              });
            case LoadBridgeMessage(pluginFile: var pluginFile):
              setState(() {
                isRunningPlugin = true;
              });
            case UnloadBridgeMessage():
              setState(() {
                isRunningPlugin = false;
              });
            case ResponseBridgeMessage(result: var result):
              setState(() {
                this.result = result.toString();
              });
            default:
              debugPrint(event);
          }
        }
      });
    } else if (pluginBridge != null) {
      pluginBridge?.stdin.write(jsonEncode(StopBridgeMessage().toJson()));
    }
  }

  void _sendRequest2Plugin() async {
    var a = int.tryParse(firstNumberController.text);
    var b = int.tryParse(secondNumberController.text);

    if (a != null && b != null) {
      pluginBridge?.stdin.write(
        jsonEncode(
          RequestBridgeMessage(a, b).toJson(),
        ),
      );
    }
  }

  void _loadAndUnloadPlugin() async {
    if (isRunningPlugin) {
      pluginBridge?.stdin.write(
        jsonEncode(
          UnloadBridgeMessage('').toJson(),
        ),
      );
    } else {
      if (selectedPlugin > -1 && selectedPlugin < plugins.length) {
        pluginBridge?.stdin.write(
          jsonEncode(
            LoadBridgeMessage(plugins[selectedPlugin]).toJson(),
          ),
        );
      }
    }
  }

  // ListView с выделяемыми элементами
  Widget _buildListView(List<String> plugins) {
    return SizedBox(
        height: 250,
        width: 500,
        child: ListView.builder(
          itemCount: plugins.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              onTap: () {
                setState(() {
                  selectedPlugin = index;
                });
              },
              selected: selectedPlugin == index,
              selectedColor: Colors.lightGreen,
              textColor: Colors.red,
              title: Text(plugins[index], style: const TextStyle(fontSize: 40)),
            );
          },
        ));
  }

  void _pickFileDialog() async {
    String? path = await FilePicker.platform.getDirectoryPath(
      lockParentWindow: true,
    );

    setState(() {
      pathToPlugins = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 30),
            Row(
              // crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: _setPathToPluginBridge,
                  style: pathToPluginBridge != null
                      ? FilledButton.styleFrom(backgroundColor: Colors.green)
                      : FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                  child: const Text('Set Plugin Bridge'),
                ),
                const SizedBox(width: 30),
                FilledButton(
                  onPressed: _pickFileDialog,
                  style: pathToPlugins != null
                      ? FilledButton.styleFrom(backgroundColor: Colors.green)
                      : FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                  child: const Text('Set Plugins Dir'),
                ),
                const SizedBox(width: 30),
                FilledButton(
                  onPressed: _updateHandle,
                  child: const Text("Update Plugin's"),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: _runPluginBridge,
                  style: pluginBridge != null
                      ? FilledButton.styleFrom(backgroundColor: Colors.green)
                      : FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                  child: pluginBridge != null
                      ? const Text('Stop Plugin')
                      : const Text('Run Plugin Bridge'),
                ),
                const SizedBox(width: 30),
                FilledButton(
                  onPressed: _loadAndUnloadPlugin,
                  style: isRunningPlugin
                      ? FilledButton.styleFrom(backgroundColor: Colors.green)
                      : FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                  child: !isRunningPlugin
                      ? const Text('Load Plugin')
                      : const Text('Unload Plugin'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildListView(plugins),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: firstNumberController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter first number',
                      hintText: 'Enter first number',
                    ),
                  ),
                ),
                const SizedBox(width: 30),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: secondNumberController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter second number',
                      hintText: 'Enter second number',
                    ),
                  ),
                ),
              ],
            ),
            Text(
              result ?? '',
              style: const TextStyle(fontSize: 33),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendRequest2Plugin,
        tooltip: 'Lets go!',
        child: const Icon(Icons.rocket),
      ),
    );
  }
}
