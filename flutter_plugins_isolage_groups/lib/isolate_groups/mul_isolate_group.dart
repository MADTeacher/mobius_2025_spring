import 'dart:isolate';

import '../plugin_bridge/plugin_message.dart';

void main(List<String> args, SendPort mainIGroup) async {
  ReceivePort port = ReceivePort();

  mainIGroup.send(StartPluginMessage(port.sendPort, 'Multiply plugin').toJson());

  port.listen((data) {
    var message = PluginMessage.fromJson(data);
    switch (message) {
      case StopPluginMessage():
        mainIGroup.send(StopPluginMessage().toJson());
        port.close();
        Isolate.current.kill();
      case RequestPluginMessage(
          firstValue: int a,
          secondValue: int b,
        ):
        var result = a * b;
        mainIGroup.send(ResponsePluginMessage(result).toJson());
      case StartPluginMessage() || ResponsePluginMessage():
        print('Message is not supported');
    }
  });
}
