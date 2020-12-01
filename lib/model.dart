/**
 * 对应MobileIMSDK中Protocal类
 */

class MobileIMSDKRecieveProtocal {
  String to;
  String from;
  String fp;
  String dataContent;
  int type;
  int typeu;
  bool bridge;
  bool qoS;

  MobileIMSDKRecieveProtocal({
    this.to,
    this.from,
    this.dataContent,
    this.fp,
    this.type,
    this.typeu,
    this.bridge,
    this.qoS,
  });

  MobileIMSDKRecieveProtocal.fromJson(Map<dynamic, dynamic> json) {
    to = json['to'];
    from = json['from'];
    dataContent = json['dataContent'];
    fp = json['fp'];
    type = json['type'];
    typeu = json['typeu'];
    bridge = json['bridge'];
    qoS = json['qoS'];
  }
}

/**
 * 收到的消息
 */
class MobileIMSDKRecieveMessageInfo {
  String fingerPrint;
  String userId;
  String dataContent;
  int typeu;

  MobileIMSDKRecieveMessageInfo({this.fingerPrint, this.userId, this.dataContent, this.typeu});

  MobileIMSDKRecieveMessageInfo.fromJson(Map<dynamic, dynamic> json) {
    fingerPrint = json['fingerPrint'];
    userId = json['userId'];
    dataContent = json['dataContent'];
    typeu = json['typeu'];
  }
}

/**
 * 收到的消息
 */
class MobileIMSDKErrorResponseInfo {
  String errorMsg;
  bool isUnlogin;
  int errorCode;

  MobileIMSDKErrorResponseInfo({this.errorMsg, this.isUnlogin, this.errorCode});

  MobileIMSDKErrorResponseInfo.fromJson(Map<dynamic, dynamic> json) {
    errorMsg = json['errorMsg'];
    isUnlogin = json['isUnlogin'];
    errorCode = json['errorCode'];
  }
}

/**
 * MobileIMSDK登录信息
 */
class MobileIMSDKLoginInfo {
  String userId;
  String token;
  String extra;

  MobileIMSDKLoginInfo.fromJson(Map<dynamic, dynamic> json) {
    userId = json['currentLoginUserId'];
    token = json['currentLoginToken'];
    extra = json['currentLoginExtra'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = Map<String, dynamic>();
    data['currentLoginUserId'] = userId;
    data['currentLoginToken'] = token;
    data['currentLoginExtra'] = extra;
    return data;
  }
}
