import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobileimsdk_tcp/flutter_mobileimsdk_tcp.dart';

class _IMInfo {
  final String content;
  final Color color;
  _IMInfo({this.color, this.content});
}

class MobileIMSDKDebugPage extends StatefulWidget {
  final MobileIMSDKLoginInfo loginInfo;
  final StreamController<FlutterMobileIMSDKMethod> streamController;

  const MobileIMSDKDebugPage({Key key, this.loginInfo, this.streamController}) : super(key: key);
  @override
  _MobileIMSDKDebugPageState createState() => _MobileIMSDKDebugPageState();
}

class _MobileIMSDKDebugPageState extends State<MobileIMSDKDebugPage> with TickerProviderStateMixin {
  TextEditingController receiverIdController = TextEditingController();
  TextEditingController messageController = TextEditingController();
  ScaffoldState _scaffoldState;
  StreamSubscription _streamSubscription;

  StreamController<bool> _connectStatusStreamController = StreamController<bool>();

  AnimationController _reloginAnimationController;
  AnimationController _keepAliveAnimationController;
  AnimationController _qosSendAnimationController;
  AnimationController _qosReceiveAnimationController;

  List<_IMInfo> _infoList = [];

  @override
  void initState() {
    super.initState();
    initDaemonStatus();
    _reloginAnimationController = AnimationController(vsync: this, duration: Duration(seconds: 1));
    _keepAliveAnimationController = AnimationController(vsync: this, duration: Duration(seconds: 1));
    _qosSendAnimationController = AnimationController(vsync: this, duration: Duration(seconds: 1));
    _qosReceiveAnimationController = AnimationController(vsync: this, duration: Duration(seconds: 1));
    refreshConnectedStatus();
    _streamSubscription = widget.streamController.stream.listen((event) {
      MobileIMSDKMethodType type = event.type;
      switch (type) {
        case MobileIMSDKMethodType.loginSuccess:
          if (event is MobileIMSDKLoginSuccess) {
            refreshConnectedStatus();
            setState(() {
              _infoList.add(_IMInfo(content: '登录成功', color: Colors.green));
            });
          }
          break;
        case MobileIMSDKMethodType.loginFail:
          if (event is MobileIMSDKLoginFail) {
            setState(() {
              _infoList.add(_IMInfo(content: 'IM服务器登录/连接失败,code=${event.errorCode}', color: Colors.red));
            });
          }
          break;
        case MobileIMSDKMethodType.linkClose:
          if (event is MobileIMSDKLinkClose) {
            refreshConnectedStatus();
            setState(() {
              _infoList.add(_IMInfo(content: '与IM服务器的连接已断开, 自动登陆/重连将启动!,code=${event.errorCode}', color: Colors.red));
            });
          }
          break;
        case MobileIMSDKMethodType.onRecieveMessage:
          if (event is MobileIMSDKRecieveMessage) {
            setState(() {
              _infoList.add(_IMInfo(content: '${event.info?.userId}说${event.info?.dataContent}', color: Colors.black));
            });
          }
          break;
        case MobileIMSDKMethodType.onErrorResponse:
          if (event is MobileIMSDKErrorResponse) {
            setState(() {
              if (event.info?.isUnlogin == true) {
                _infoList.add(_IMInfo(content: '服务端会话已失效，自动登陆/重连将启动! ,code=${event.info.errorCode}', color: Colors.red[200]));
              } else {
                _infoList.add(_IMInfo(content: '服务端会话已失效，自动登陆/重连将启动! ,Server反馈错误码：code=${event.info.errorCode},errorMsg=${event.info.errorMsg}', color: Colors.red));
              }
            });
          }
          break;
        case MobileIMSDKMethodType.qosMessagesLost:
          if (event is MobileIMSDKMessagesLost) {
            setState(() {
              _infoList.add(_IMInfo(content: '[消息未成功送达]共${event.protocalList?.length}条!(网络状况不佳或对方id不存在)', color: Colors.red[200]));
            });
          }
          break;
        case MobileIMSDKMethodType.qosMessagesBeReceived:
          if (event is MobileIMSDKMessagesBeReceived) {
            setState(() {
              _infoList.add(_IMInfo(content: '[收到应答]${event.fingerPrint}', color: Colors.blue));
            });
          }
          break;
        case MobileIMSDKMethodType.autoReLoginDaemonObserver:
          if (event is MobileIMSDKDaemonOberber) {
            int status = event.status == 1 || event.status == 2 ? 1 : 0;
            _reloginAnimationController.stop();
            if (status == 0) {
              _reloginAnimationController.value = 0;
            } else {
              _reloginAnimationController.value = 0.1;
              _reloginAnimationController.forward();
            }
          }
          break;
        case MobileIMSDKMethodType.keepAliveDaemonObserver:
          if (event is MobileIMSDKDaemonOberber) {
            int status = event.status == 1 || event.status == 2 ? 1 : 0;
            _keepAliveAnimationController.stop();
            if (status == 0) {
              _keepAliveAnimationController.value = 0;
            } else {
              _keepAliveAnimationController.value = 0.1;
              _keepAliveAnimationController.forward();
            }
          }
          break;
        case MobileIMSDKMethodType.qoS4SendDaemonObserver:
          if (event is MobileIMSDKDaemonOberber) {
            int status = event.status == 1 || event.status == 2 ? 1 : 0;
            _qosSendAnimationController.stop();
            if (status == 0) {
              _qosSendAnimationController.value = 0;
            } else {
              _qosSendAnimationController.value = 0.1;
              _qosSendAnimationController.forward();
            }
          }
          break;
        case MobileIMSDKMethodType.qoS4ReciveDaemonObserver:
          if (event is MobileIMSDKDaemonOberber) {
            int status = event.status == 1 || event.status == 2 ? 1 : 0;
            _qosReceiveAnimationController.stop();
            if (status == 0) {
              _qosReceiveAnimationController.value = 0;
            } else {
              _qosReceiveAnimationController.value = 0.1;
              _qosReceiveAnimationController.forward();
            }
          }
          break;
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _connectStatusStreamController?.close();
    _keepAliveAnimationController.dispose();
    _reloginAnimationController.dispose();
    _qosSendAnimationController.dispose();
    _qosReceiveAnimationController.dispose();
    super.dispose();
  }

  void initDaemonStatus() {
    FlutterMobileImsdk.isAutoReLoginRunning().then((value) {
      if (value.result == true) {
        if (value.value == true) {
          _reloginAnimationController.value = 1;
        } else {
          _reloginAnimationController.value = 0;
        }
      }
    });
    FlutterMobileImsdk.isKeepAliveRunning().then((value) {
      if (value.result == true) {
        if (value.value == true) {
          _keepAliveAnimationController.value = 1;
        } else {
          _keepAliveAnimationController.value = 0;
        }
      }
    });
    FlutterMobileImsdk.isQoS4SendDaemonRunning().then((value) {
      if (value.result == true) {
        if (value.value == true) {
          _qosSendAnimationController.value = 1;
        } else {
          _qosSendAnimationController.value = 0;
        }
      }
    });
    FlutterMobileImsdk.isQoS4ReciveDaemonRunning().then((value) {
      if (value.result == true) {
        if (value.value == true) {
          _qosReceiveAnimationController.value = 1;
        } else {
          _qosReceiveAnimationController.value = 0;
        }
      }
    });
  }

  void animate(ValueChanged<int> callback) {
    Future.delayed(Duration(milliseconds: 500), () {
      callback(2);
    });
    Future.delayed(Duration(milliseconds: 1000), () {
      callback(1);
    });
  }

  void refreshConnectedStatus() {
    FlutterMobileImsdk.getConnectedStatus().then((value) {
      if (value.result == true) {
        _connectStatusStreamController.add(value.value == true);
      }
    });
  }

  void sendMessage() {
    if (receiverIdController.text.isEmpty) {
      showToast('请输入对方id');
    } else if (messageController.text.isEmpty) {
      showToast('请输入消息内容');
    } else {
      setState(() {
        _infoList.add(_IMInfo(content: '我对${receiverIdController.text}说：${messageController.text}', color: Colors.black));
      });
      FlutterMobileImsdk.sendMessage(dataContent: messageController.text, toUserId: receiverIdController.text, qos: true).then((value) {
        if (value.result == false || value.value == false) {
          showToast('消息发送失败');
        }
      });
    }
  }

  void logout() {
    FlutterMobileImsdk.logout().then((value) {
      if (value.result == true) {
        Navigator.pop(context);
      } else {
        showToast('退出登录失败');
      }
    });
  }

  void showToast(String toast) {
    _scaffoldState.showSnackBar(SnackBar(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(toast),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 1),
    ));
  }

  Color colorForAnimationValue(double value) {
    if (value < 0.1) {
      return Colors.grey;
    } else if (value < 0.9) {
      return Colors.lightGreen;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        backgroundColor: Color.fromRGBO(239, 239, 245, 1),
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text('MobileIMSDK_TCP Demo'),
        ),
        body: StatefulBuilder(
          builder: (ctx, _) {
            _scaffoldState = Scaffold.of(ctx);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              StreamBuilder(
                                builder: (_, snapshot) {
                                  return Text('通信状态：${snapshot.data == true ? '通信正常' : '连接断开'}');
                                },
                                stream: _connectStatusStreamController.stream,
                              ),
                              Text('当前账号：${widget.loginInfo?.userId}'),
                            ],
                          ),
                          FlatButton(
                            color: Colors.orange,
                            onPressed: logout,
                            child: Text(
                              '退出登陆',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    Container(
                      height: 40,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: receiverIdController,
                              style: TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: '接收方的id',
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 8,
                                ),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            flex: 4,
                            child: TextField(
                              controller: messageController,
                              style: TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: '发送的消息',
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 8,
                                ),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    FlatButton(
                      color: Colors.green,
                      minWidth: BoxConstraints.expand().maxWidth,
                      onPressed: sendMessage,
                      child: Text(
                        '发送消息',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '线程动态：',
                          style: TextStyle(fontSize: 11, color: Colors.blue),
                        ),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                            children: [
                              WidgetSpan(
                                child: AnimatedBuilder(
                                  animation: _reloginAnimationController,
                                  builder: (_, __) {
                                    return Container(
                                      width: 11,
                                      height: 11,
                                      margin: const EdgeInsets.only(left: 6, right: 2),
                                      decoration: BoxDecoration(
                                        color: colorForAnimationValue(_reloginAnimationController.value),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              TextSpan(text: '掉线重连'),
                              WidgetSpan(
                                child: AnimatedBuilder(
                                  animation: _keepAliveAnimationController,
                                  builder: (_, __) {
                                    return Container(
                                      width: 11,
                                      height: 11,
                                      margin: const EdgeInsets.only(left: 6, right: 2),
                                      decoration: BoxDecoration(
                                        color: colorForAnimationValue(_keepAliveAnimationController.value),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              TextSpan(text: 'KeepAlive'),
                              WidgetSpan(
                                child: AnimatedBuilder(
                                  animation: _qosSendAnimationController,
                                  builder: (_, __) {
                                    return Container(
                                      width: 11,
                                      height: 11,
                                      margin: const EdgeInsets.only(left: 6, right: 2),
                                      decoration: BoxDecoration(
                                        color: colorForAnimationValue(_qosSendAnimationController.value),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              TextSpan(text: 'Qos(发)'),
                              WidgetSpan(
                                child: AnimatedBuilder(
                                  animation: _qosReceiveAnimationController,
                                  builder: (_, __) {
                                    return Container(
                                      width: 11,
                                      height: 11,
                                      margin: const EdgeInsets.only(left: 6, right: 2),
                                      decoration: BoxDecoration(
                                        color: colorForAnimationValue(_qosReceiveAnimationController.value),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              TextSpan(text: 'Qos(收)'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: ListView(
                          reverse: true,
                          children: [
                            ..._infoList.reversed.map(
                              (e) => Text(
                                e.content,
                                style: TextStyle(
                                  color: e.color,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
