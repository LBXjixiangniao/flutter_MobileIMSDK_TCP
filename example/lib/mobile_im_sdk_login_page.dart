import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobileimsdk_tcp/flutter_mobileimsdk_tcp.dart';

import 'custom_dialog.dart';
import 'mobile_im_sdk_debug_page.dart';

class MobileIMSDKLoginPage extends StatefulWidget {
  @override
  _MobileIMSDKLoginPageState createState() => _MobileIMSDKLoginPageState();
}

class _MobileIMSDKLoginPageState extends State<MobileIMSDKLoginPage> {
  TextEditingController ipController = TextEditingController(text: 'rbcore.52im.net');
  TextEditingController portController = TextEditingController(text: '8901');
  TextEditingController accountController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  StreamController<FlutterMobileIMSDKMethod> _streamController = StreamController<FlutterMobileIMSDKMethod>.broadcast();

  ScaffoldState _scaffoldState;

  StreamSubscription _streamSubscription;

  @override
  void initState() {
    super.initState();
    FlutterMobileImsdk.setMethodCallHandler(handler: (method) {
      _streamController.add(method);
    });

    _streamSubscription = _streamController.stream.listen((event) {
      if (event is MobileIMSDKLoginSuccess) {
        print(event.info.toJson());
        // showToast('登录成功');
        Navigator.pop(context);
        _streamSubscription.pause();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MobileIMSDKDebugPage(
              loginInfo: event.info,
              streamController: _streamController,
            ),
          ),
        ).whenComplete(() {
          _streamSubscription.resume();
        });
      } else if (event is MobileIMSDKLoginFail) {
        showToast('登录失败');
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _streamController.close();
    super.dispose();
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

  void login() {
    FocusScope.of(context).requestFocus(FocusNode());
    if (ipController.text.isEmpty || portController.text.isEmpty) {
      showToast('请填写服务器ip和端口号');
    } else if (accountController.text.isEmpty || passwordController.text.isEmpty) {
      showToast('请填用户名和密码');
    } else {
      showDefaultLoading(context: context, title: '正在登录...');
      FlutterMobileImsdk.initMobileIMSDK(serverIP: ipController.text, serverPort: int.parse(portController.text), debug: true).then((value) {
        if (value.result == true) {
          FlutterMobileImsdk.login(loginUserId: accountController.text, loginToken: passwordController.text).then((value) {
            if (value.result == false) {
              showToast('登录失败');
              Navigator.pop(context);
            }
          }).catchError((onError) {
            showToast('登录失败');
            Navigator.pop(context);
          });
        } else {
          showToast('登录失败');
          Navigator.pop(context);
        }
      }).catchError((onError) {
        showToast('登录失败');
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('MobileIMSDK_TCP Demo登录'),
          centerTitle: true,
        ),
        body: StatefulBuilder(
          builder: (ctx, _) {
            _scaffoldState = Scaffold.of(ctx);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 30,
                  ),
                  Container(
                    height: 40,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: ipController,
                            decoration: InputDecoration(
                              hintText: '请输入服务端ip',
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 8,
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          width: 18,
                          child: Text(':'),
                        ),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: portController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '请输入服务端端口号',
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
                  SizedBox(height: 16),
                  Container(
                    height: 40,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: accountController,
                            decoration: InputDecoration(
                              hintText: '登录用户名',
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 8,
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              hintText: '登录密码',
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
                  SizedBox(height: 30),
                  FlatButton(
                    color: Colors.blue,
                    minWidth: BoxConstraints.expand().maxWidth,
                    onPressed: login,
                    child: Text(
                      '登录',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
