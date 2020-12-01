import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'method.dart';
import 'model.dart';

export 'method.dart';
export 'model.dart';

class FlutterMobileIMSDKResult {
  bool result;
  dynamic value;

  FlutterMobileIMSDKResult(this.result, this.value);

  FlutterMobileIMSDKResult.fromJson(Map<dynamic, dynamic> json) {
    if (json == null) {
      result = false;
      return;
    }
    result = json['result'] == true;
    value = json['value'];
  }
}
/**
SenseMode3S
此模式下：
* KeepAlive心跳问隔为3秒；
* 10秒后未收到服务端心跳反馈即认为连接已断开（相当于连续3 个心跳间隔后仍未收到服务端反馈）。

SenseMode10S
此模式下：
* KeepAlive心跳问隔为10秒；
* 21秒后未收到服务端心跳反馈即认为连接已断开（相当于连续2 个心跳间隔后仍未收到服务端反馈）。

SenseMode30S
此模式下：
* KeepAlive心跳问隔为30秒；
* 61秒后未收到服务端心跳反馈即认为连接已断开（相当于连续2 个心跳间隔后仍未收到服务端反馈）。

SenseMode60S
此模式下：
* KeepAlive心跳问隔为60秒；
* 121秒后未收到服务端心跳反馈即认为连接已断开（相当于连续2 个心跳间隔后仍未收到服务端反馈）。

SenseMode120S
此模式下：
* KeepAlive心跳问隔为120秒；
* 241秒后未收到服务端心跳反馈即认为连接已断开（相当于连续2 个心跳间隔后仍未收到服务端反馈）。
*/
enum MobileIMSDKSenseMode {
  SenseMode3S,
  SenseMode10S,
  SenseMode30S,
  SenseMode60S,
  SenseMode120S,
}

class FlutterMobileImsdk {
  static const MethodChannel _channel = const MethodChannel('flutter_mobileimsdk_tcp');

  static setMethodCallHandler({ValueChanged<FlutterMobileIMSDKMethod> handler}) {
    if (handler != null) {
      _channel.setMethodCallHandler((call) async {
        handler.call(FlutterMobileIMSDKMethod.fromMethodCall(call));
      });
    } else {
      _channel.setMethodCallHandler(null);
    }
  }

  /**
 * 初始化SDK。// 提示：在不退出APP的情况下退出登陆后再重新登陆时，请确保调用本方法一次，不然会报code=203错误哦！
 * 
 * serverIP:服务器ip地址
 * serverPort：服务器端口号
 * appKey：根据社区回答，暂时无用
 * senseMode：KeepAlive心跳问隔.客户端本模式的设定必须要与服务端的模式设制保持一致，否则 可能因参数的不一致而导致IM算法的不匹配，进而出现不可预知的问题。
 * debug：true表示开启MobileIMSDK Debug信息在控制台下的输出，否则关闭。sdk默认为NO
 * 
 * result->{
 * result:bool, //标识接口调用是否成功
*/
  static Future<FlutterMobileIMSDKResult> initMobileIMSDK({
    @required String serverIP,
    @required int serverPort,
    String appKey,
    MobileIMSDKSenseMode senseMode,
    bool debug,
  }) {
    Map<String, dynamic> arguments = {};
    arguments['serverIP'] = serverIP;
    arguments['serverPort'] = serverPort;
    if (appKey != null) {
      arguments['appKey'] = appKey;
    }
    if (senseMode != null) {
      arguments['senseMode'] = senseMode.index;
    }
    if (debug != null) {
      arguments['debug'] = debug;
    }

    return _channel
        .invokeMethod('initMobileIMSDK', arguments)
        .then((value) => FlutterMobileIMSDKResult.fromJson(value));
  }

  /**
   * 退出登录重新登录记得要调一下initMobileIMSDK方法，不然会报code=203错误哦！
 * 发送登陆信息.本方法中已经默认进行了核心库的初始化，因而使用本类完成登陆时，就无需单独 调用初始化方法[ClientCoreSDK initCore]了。
 * 
 * loginUserId:提交到服务端的准一id，保证唯一就可以通信，可能是登陆用户名、 也可能是任意不重复的id等，具体意义由业务层决定
 * loginToken:提交到服务端用于身份鉴别和合法性检查的token，它可能是登陆密码 ，也可能是通过前置单点登陆接口拿到的token等，具体意义由业务层决定
 * extra:额外信息字符串，可为null。本字段目前为保留字段，供上层应用自行放置需要的内容
 * 
 * result->{
 * result:bool, //标识接口调用是否成功
*/
  static Future<FlutterMobileIMSDKResult> login({
    @required String loginUserId,
    @required String loginToken,
    String extra,
  }) {
    Map<String, dynamic> arguments = {};
    arguments['loginUserId'] = loginUserId;
    arguments['loginToken'] = loginToken;
    if (extra != null) {
      arguments['extra'] = extra;
    }
    return _channel
        .invokeMethod('login', arguments)
        .then((value) => FlutterMobileIMSDKResult.fromJson(value));
  }

  /**
 * 发送注销登陆信息。此方法的调用将被本库理解为退出库的使用，本方法将会额外调 用资源释放方法 [ClientCoreSDK releaseCore]，以保证资源释放。
 * 
 * result->{
 * result:bool, //标识接口调用是否成功
*/
  static Future<FlutterMobileIMSDKResult> logout() {
    return _channel
        .invokeMethod(
          'logout',
        )
        .then((value) => FlutterMobileIMSDKResult.fromJson(value));
  }

/**
 * 通用数据发送方法（sdk默认不需要Qos支持）。
 * 
 * dataContent:要发送的数据内容（字符串方式组织）
 * toUserId:要发送到的目标用户id
 * fingerPrint:QoS机制中要用到的指纹码（即消息包唯一id）
 * qos:true表示需QoS机制支持，不则不需要
 * typeu:业务层自定义type类型
 * 
 * result->{
 * result:bool, //标识接口调用是否成功
*/
  static Future<FlutterMobileIMSDKResult> sendMessage({
    @required String dataContent,
    @required String toUserId,
    String fingerPrint,
    bool qos,
    int typeu,
  }) {
    Map<String, dynamic> arguments = {};
    arguments['dataContent'] = dataContent;
    arguments['toUserId'] = toUserId;
    if (fingerPrint != null) {
      arguments['fingerPrint'] = fingerPrint;
    }
    if (qos != null) {
      arguments['qos'] = qos;
    }
    if (typeu != null) {
      arguments['typeu'] = typeu;
    }
    return _channel
        .invokeMethod('sendMessage', arguments)
        .then((value) => FlutterMobileIMSDKResult.fromJson(value));
  }

  /**
 * 获取与服务器连接状态
 * 
 * result->{
 * result:bool, //标识接口调用是否成功
 * value:bool,//接口返回的连接状态，true表示通信正常，false表示断开连接
*/
  static Future<FlutterMobileIMSDKResult> getConnectedStatus() {
    return _channel.invokeMethod('getConnectedStatus').then((value) => FlutterMobileIMSDKResult.fromJson(value));
  }

  /**
 * 获取当前登录信息
 * result->{
 * result:bool, //标识接口调用是否成功
 * value:MobileIMSDKLoginInfo,//接口返回的登录信息
*/
  static Future<FlutterMobileIMSDKResult> getCurrentLoginInfo() {
    return _channel.invokeMethod('getCurrentLoginInfo').then((value) {
      FlutterMobileIMSDKResult result = FlutterMobileIMSDKResult.fromJson(value);
      if (result.result == true && result.value is Map) {
        result.value = MobileIMSDKLoginInfo.fromJson(result.value);
      }
      return result;
    });
  }

  /**
 * 自动登录重连进程是否正在运行
 * 
 * result->{
 * result:bool, //标识接口调用是否成功
 * value:bool,//接口返回的连接状态，true表示进程正在运行，false表示程正不在运行状态
*/
  static Future<FlutterMobileIMSDKResult> isAutoReLoginRunning() {
    return _channel.invokeMethod('isAutoReLoginRunning').then((value) => FlutterMobileIMSDKResult.fromJson(value));
  }

  /**
 * keepAlive进程是否正在运行
 * result->{
 * result:bool, //标识接口调用是否成功
 * value:bool,//接口返回的连接状态，true表示进程正在运行，false表示程正不在运行状态
*/
  static Future<FlutterMobileIMSDKResult> isKeepAliveRunning() {
    return _channel.invokeMethod('isKeepAliveRunning').then((value) => FlutterMobileIMSDKResult.fromJson(value));
  }

  /**
 * QoS4Send进程是否正在运行
 * 
 * result->{
 * result:bool, //标识接口调用是否成功
 * value:bool,//接口返回的连接状态，true表示进程正在运行，false表示程正不在运行状态
*/
  static Future<FlutterMobileIMSDKResult> isQoS4SendDaemonRunning() {
    return _channel.invokeMethod('isQoS4SendDaemonRunning').then((value) => FlutterMobileIMSDKResult.fromJson(value));
  }

  /**
 * QoS4Recive进程是否正在运行
 * 
 * result->{
 * result:bool, //标识接口调用是否成功
 * value:bool,//接口返回的连接状态，true表示进程正在运行，false表示程正不在运行状态
*/
  static Future<FlutterMobileIMSDKResult> isQoS4ReciveDaemonRunning() {
    return _channel.invokeMethod('isQoS4ReciveDaemonRunning').then((value) => FlutterMobileIMSDKResult.fromJson(value));
  }
}
