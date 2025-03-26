import 'dart:isolate';

enum PluginMessageType {
  start,
  stop,
  request,
  response;

  static PluginMessageType fromString(String value) {
    return switch (value) {
      'start' => PluginMessageType.start,
      'request' => PluginMessageType.request,
      'response' => PluginMessageType.response,
      'stop' => PluginMessageType.stop,
      _ => throw Exception('Unknown message type: $value'),
    };
  }
}

sealed class PluginMessage {
  final PluginMessageType type;
  PluginMessage({required this.type});

  factory PluginMessage.fromJson(Map<String, dynamic> json) {
    if (json case {'type': var type}) {
      var msType = PluginMessageType.fromString(type);
      return switch (msType) {
        PluginMessageType.start => StartPluginMessage.fromJson(json),
        PluginMessageType.stop => StopPluginMessage.fromJson(json),
        PluginMessageType.request => RequestPluginMessage.fromJson(
            json,
          ),
        PluginMessageType.response => ResponsePluginMessage.fromJson(
            json,
          ),
      };
    }

    throw Exception('Unknown message: $json');
  }

  Map<String, dynamic> toJson();
}

class StartPluginMessage extends PluginMessage {
  final SendPort sender;
  final String hello;
  StartPluginMessage(
    this.sender,
    this.hello, {
    super.type = PluginMessageType.start,
  });

  factory StartPluginMessage.fromJson(Map<String, dynamic> json) {
    return StartPluginMessage(json['sender'], json['hello']);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type.name, 'sender': sender, 'hello': hello};
  }
}



class StopPluginMessage extends PluginMessage {
  StopPluginMessage({super.type = PluginMessageType.stop});

  factory StopPluginMessage.fromJson(Map<String, dynamic> json) {
    return StopPluginMessage();
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
    };
  }
}

class RequestPluginMessage extends PluginMessage {
  final int firstValue;
  final int secondValue;

  RequestPluginMessage(
    this.firstValue,
    this.secondValue, {
    super.type = PluginMessageType.request,
  });

  factory RequestPluginMessage.fromJson(Map<String, dynamic> json) {
    return RequestPluginMessage(
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

class ResponsePluginMessage extends PluginMessage {
  final int result;
  ResponsePluginMessage(
    this.result, {
    super.type = PluginMessageType.response,
  });

  factory ResponsePluginMessage.fromJson(Map<String, dynamic> json) {
    if (json case {'type': 'response', 'result': int data}) {
      return ResponsePluginMessage(data);
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
