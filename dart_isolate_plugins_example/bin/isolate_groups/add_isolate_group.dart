import 'dart:isolate';

import '../message.dart';

void main(List<String> args, SendPort mainIGroup) async {
  ReceivePort port = ReceivePort();

  mainIGroup.send(StartMessage(port.sendPort, 'Add plugin').toJson());

  port.listen((data) {
    var message = Message.fromJson(data);
    switch (message) {
      case StopMessage():
        mainIGroup.send(StopMessage().toJson());
        port.close();
        Isolate.current.kill();
      case RequestMessage(
          firstValue: int a,
          secondValue: int b,
        ):
        var result = a + b;
        mainIGroup.send(ResponseMessage(result).toJson());
      case StartMessage() || ResponseMessage():
        print('Message is not supported');
    }
  });
}
