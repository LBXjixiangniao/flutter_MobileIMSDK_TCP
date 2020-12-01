import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'model.dart';

///flutter层定义的method type
enum MobileIMSDKMethodType {
  loginSuccess,
  loginFail,
  linkClose,
  onRecieveMessage,
  onErrorResponse,
  qosMessagesLost,
  qosMessagesBeReceived,

  ///注意：设置debug模式下才会监听该消息
  autoReLoginDaemonObserver,
  ///注意：设置debug模式下才会监听该消息
  keepAliveDaemonObserver,
  ///注意：设置debug模式下才会监听该消息
  qoS4SendDaemonObserver,
  ///注意：设置debug模式下才会监听该消息
  qoS4ReciveDaemonObserver,
}

///将native中channel.invokeMethod传递过来的事件转换成MobileIMSDKMethodType
extension MobileIMSDKMethodTypeExtension on MobileIMSDKMethodType {
  static fromMethodCallName(String name) {
    switch (name) {
      case 'AutoReLoginDaemonObserver':
        return MobileIMSDKMethodType.autoReLoginDaemonObserver;
      case 'KeepAliveDaemonObserver':
        return MobileIMSDKMethodType.keepAliveDaemonObserver;
      case 'QoS4SendDaemonObserver':
        return MobileIMSDKMethodType.qoS4SendDaemonObserver;
      case 'QoS4ReciveDaemonObserver':
        return MobileIMSDKMethodType.qoS4ReciveDaemonObserver;
      case 'loginSuccess':
        return MobileIMSDKMethodType.loginSuccess;
      case 'loginFail':
        return MobileIMSDKMethodType.loginFail;
      case 'linkClose':
        return MobileIMSDKMethodType.linkClose;
      case 'onRecieveMessage':
        return MobileIMSDKMethodType.onRecieveMessage;
      case 'onErrorResponse':
        return MobileIMSDKMethodType.onErrorResponse;
      case 'qosMessagesLost':
        return MobileIMSDKMethodType.qosMessagesLost;
      case 'qosMessagesBeReceived':
        return MobileIMSDKMethodType.qosMessagesBeReceived;
    }
    return null;
  }
}


class FlutterMobileIMSDKMethod {
  MobileIMSDKMethodType type;
  dynamic argument;

  FlutterMobileIMSDKMethod(this.type, this.argument);

  factory FlutterMobileIMSDKMethod.fromMethodCall(MethodCall call) {
    MobileIMSDKMethodType type = MobileIMSDKMethodTypeExtension.fromMethodCallName(call.method);
    switch (type) {
      case MobileIMSDKMethodType.autoReLoginDaemonObserver:
      case MobileIMSDKMethodType.keepAliveDaemonObserver:
      case MobileIMSDKMethodType.qoS4SendDaemonObserver:
      case MobileIMSDKMethodType.qoS4ReciveDaemonObserver:
        return MobileIMSDKDaemonOberber(type: type, argument: call.arguments);
      case MobileIMSDKMethodType.loginSuccess:
        return MobileIMSDKLoginSuccess(type: type, argument: call.arguments);
      case MobileIMSDKMethodType.loginFail:
        return MobileIMSDKLoginFail(type: type, argument: call.arguments);
      case MobileIMSDKMethodType.linkClose:
        return MobileIMSDKLinkClose(type: type, argument: call.arguments);
      case MobileIMSDKMethodType.onRecieveMessage:
        return MobileIMSDKRecieveMessage(type: type, argument: call.arguments);
      case MobileIMSDKMethodType.onErrorResponse:
        return MobileIMSDKErrorResponse(type: type, argument: call.arguments);
      case MobileIMSDKMethodType.qosMessagesLost:
        return MobileIMSDKMessagesLost(type: type, argument: call.arguments);
      case MobileIMSDKMethodType.qosMessagesBeReceived:
        return MobileIMSDKMessagesBeReceived(type: type, argument: call.arguments);
    }
    return null;
  }
}

class MobileIMSDKDaemonOberber extends FlutterMobileIMSDKMethod {
  //1、2正常状态，其他错误状态
  int status;
  MobileIMSDKDaemonOberber({@required MobileIMSDKMethodType type, dynamic argument}) : super(type, argument) {
    if (argument is int) {
      status = argument;
    }
  }
}

class MobileIMSDKLoginSuccess extends FlutterMobileIMSDKMethod {
  MobileIMSDKLoginInfo info;
  MobileIMSDKLoginSuccess({@required MobileIMSDKMethodType type, dynamic argument}) : super(type, argument) {
    if (argument is Map) {
      info = MobileIMSDKLoginInfo.fromJson(argument);
    }
  }
}

class MobileIMSDKLoginFail extends FlutterMobileIMSDKMethod {
  int errorCode;
  MobileIMSDKLoginFail({@required MobileIMSDKMethodType type, dynamic argument}) : super(type, argument) {
    if (argument is int) {
      errorCode = argument;
    }
  }
}

class MobileIMSDKLinkClose extends FlutterMobileIMSDKMethod {
  int errorCode;
  MobileIMSDKLinkClose({@required MobileIMSDKMethodType type, dynamic argument}) : super(type, argument) {
    if (argument is int) {
      errorCode = argument;
    }
  }
}

class MobileIMSDKRecieveMessage extends FlutterMobileIMSDKMethod {
  MobileIMSDKRecieveMessageInfo info;
  MobileIMSDKRecieveMessage({@required MobileIMSDKMethodType type, dynamic argument}) : super(type, argument) {
    if (argument is Map) {
      info = MobileIMSDKRecieveMessageInfo.fromJson(argument);
    }
  }
}

class MobileIMSDKErrorResponse extends FlutterMobileIMSDKMethod {
  MobileIMSDKErrorResponseInfo info;
  MobileIMSDKErrorResponse({@required MobileIMSDKMethodType type, dynamic argument}) : super(type, argument) {
    if (argument is Map) {
      info = MobileIMSDKErrorResponseInfo.fromJson(argument);
    }
  }
}

class MobileIMSDKMessagesLost extends FlutterMobileIMSDKMethod {
  List<MobileIMSDKRecieveProtocal> protocalList;
  MobileIMSDKMessagesLost({@required MobileIMSDKMethodType type, dynamic argument}) : super(type, argument) {
    if (argument is List) {
      protocalList = argument.map((e) => MobileIMSDKRecieveProtocal.fromJson(e)).toList();
    }
  }
}

class MobileIMSDKMessagesBeReceived extends FlutterMobileIMSDKMethod {
  String fingerPrint;
  MobileIMSDKMessagesBeReceived({@required MobileIMSDKMethodType type, dynamic argument}) : super(type, argument) {
    if (argument is String) {
      fingerPrint = argument;
    }
  }
}
