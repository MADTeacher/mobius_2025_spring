import 'dart:isolate';

enum BridgeMessageType {
  start,
  stop,
  update,
  load,
  unload,
  request,
  response;

  static BridgeMessageType fromString(String value) {
    return switch (value) {
      'start' => BridgeMessageType.start,
      'request' => BridgeMessageType.request,
      'response' => BridgeMessageType.response,
      'stop' => BridgeMessageType.stop,
      'load' => BridgeMessageType.load,
      'unload' => BridgeMessageType.unload,
      'update' => BridgeMessageType.update,
      _ => throw Exception('Unknown message type: $value'),
    };
  }
}

sealed class BridgeMessage {
  final BridgeMessageType type;
  BridgeMessage({required this.type});

  factory BridgeMessage.fromJson(Map<String, dynamic> json) {
    if (json case {'type': var type}) {
      var msType = BridgeMessageType.fromString(type);
      return switch (msType) {
        BridgeMessageType.start => StartBridgeMessage.fromJson(json),
        BridgeMessageType.stop => StopBridgeMessage.fromJson(json),
        BridgeMessageType.request => RequestBridgeMessage.fromJson(
            json,
          ),
        BridgeMessageType.response => ResponseBridgeMessage.fromJson(
            json,
          ),
        BridgeMessageType.update => UpdateBridgeMessage.fromJson(json),
        BridgeMessageType.load => LoadBridgeMessage.fromJson(json),
        BridgeMessageType.unload => UnloadBridgeMessage.fromJson(json),
      };
    }

    throw Exception('Unknown message: $json');
  }

  Map<String, dynamic> toJson();
}

class StartBridgeMessage extends BridgeMessage {
  StartBridgeMessage({
    super.type = BridgeMessageType.start,
  });

  factory StartBridgeMessage.fromJson(Map<String, dynamic> json) {
    return StartBridgeMessage();
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
    };
  }
}

class StopBridgeMessage extends BridgeMessage {
  StopBridgeMessage({super.type = BridgeMessageType.stop});

  factory StopBridgeMessage.fromJson(Map<String, dynamic> json) {
    return StopBridgeMessage();
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
    };
  }
}

class RequestBridgeMessage extends BridgeMessage {
  final int firstValue;
  final int secondValue;

  RequestBridgeMessage(
    this.firstValue,
    this.secondValue, {
    super.type = BridgeMessageType.request,
  });

  factory RequestBridgeMessage.fromJson(Map<String, dynamic> json) {
    return RequestBridgeMessage(
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

class ResponseBridgeMessage extends BridgeMessage {
  final int result;
  ResponseBridgeMessage(
    this.result, {
    super.type = BridgeMessageType.response,
  });

  factory ResponseBridgeMessage.fromJson(Map<String, dynamic> json) {
    if (json case {'type': 'response', 'result': int data}) {
      return ResponseBridgeMessage(data);
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

class LoadBridgeMessage extends BridgeMessage {
  final String pluginFile;

  LoadBridgeMessage(
    this.pluginFile, {
    super.type = BridgeMessageType.load,
  });

  factory LoadBridgeMessage.fromJson(Map<String, dynamic> json) {
    return LoadBridgeMessage(
      json['plugin_file'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'plugin_file': pluginFile,
    };
  }
}

class UnloadBridgeMessage extends BridgeMessage {
  final String pluginFile;

  UnloadBridgeMessage(
    this.pluginFile, {
    super.type = BridgeMessageType.unload,
  });

  factory UnloadBridgeMessage.fromJson(Map<String, dynamic> json) {
    return UnloadBridgeMessage(
      json['plugin_file'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'plugin_file': pluginFile,
    };
  }
}

class UpdateBridgeMessage extends BridgeMessage {
  final List<String> plugins;

  UpdateBridgeMessage(
    this.plugins, {
    super.type = BridgeMessageType.update,
  });

  factory UpdateBridgeMessage.fromJson(Map<String, dynamic> json) {
    return UpdateBridgeMessage(
      (json['plugins'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'plugins': plugins,
    };
  }
}
