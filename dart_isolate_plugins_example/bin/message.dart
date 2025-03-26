import 'dart:isolate';

enum MessageType {
  start,
  stop,
  request,
  response;

  static MessageType fromString(String value) {
    return switch (value) {
      'start' => MessageType.start,
      'request' => MessageType.request,
      'response' => MessageType.response,
      'stop' => MessageType.stop,
      _ => throw Exception('Unknown message type: $value'),
    };
  }
}

sealed class Message {
  final MessageType type;
  Message({required this.type});

  factory Message.fromJson(Map<String, dynamic> json) {
    if (json case {'type': var type}) {
      var msType = MessageType.fromString(type);
      return switch (msType) {
        MessageType.start => StartMessage.fromJson(json),
        MessageType.stop => StopMessage.fromJson(json),
        MessageType.request => RequestMessage.fromJson(
            json,
          ),
        MessageType.response => ResponseMessage.fromJson(
            json,
          ),
      };
    }

    throw Exception('Unknown message: $json');
  }

  Map<String, dynamic> toJson();
}

class StartMessage extends Message {
  final SendPort sender;
  final String hello;
  StartMessage(
    this.sender,
    this.hello, {
    super.type = MessageType.start,
  });

  factory StartMessage.fromJson(Map<String, dynamic> json) {
    return StartMessage(json['sender'], json['hello']);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type.name, 'sender': sender, 'hello': hello};
  }
}

class StopMessage extends Message {
  StopMessage({super.type = MessageType.stop});

  factory StopMessage.fromJson(Map<String, dynamic> json) {
    return StopMessage();
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
    };
  }
}

class RequestMessage extends Message {
  final int firstValue;
  final int secondValue;

  RequestMessage(
    this.firstValue,
    this.secondValue, {
    super.type = MessageType.request,
  });

  factory RequestMessage.fromJson(Map<String, dynamic> json) {
    return RequestMessage(
      json['firstValue'],
      json['secondValue'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'firstValue': firstValue,
      'secondValue': secondValue,
    };
  }
}

class ResponseMessage extends Message {
  final int result;
  ResponseMessage(
    this.result, {
    super.type = MessageType.response,
  });

  factory ResponseMessage.fromJson(Map<String, dynamic> json) {
    if (json case {'type': 'response', 'result': int data}) {
      return ResponseMessage(data);
    }
    throw ArgumentError.value(json, 'WTF', "It isn't result");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'result': result,
    };
  }
}
