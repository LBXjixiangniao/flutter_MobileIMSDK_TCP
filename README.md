# flutter_MobileIMSDK_TCP
开源项目https://github.com/JackJiang2011/MobileIMSDK 的TCP封装。
UDP：https://pub.dev/packages/flutter_mobile_imsdk

## 用法

### 初始化sdk
**提示：** 在不退出APP的情况下退出登陆后再重新登陆时，请确保调用本方法一次，不然会报code=203错误哦！
```
/**
 * 初始化SDK 
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
FlutterMobileImsdk.initMobileIMSDK(
              serverIP: '服务端ip', serverPort:服务端端口号 )
          .then((value) {
        if (value.result == true) {
          //初始化成功
        } else {
          //初始化失败
        }
      }).catchError((onError) {
        //初始化失败
      });
```

### 登录
登录前一定要先初始化sdk，设置ip和端口号
退出登录重新登录记得要调一下initMobileIMSDK方法，不然会报code=203错误哦！
```
FlutterMobileImsdk.login(loginUserId: accountController.text, loginToken: passwordController.text)
              .then((value) {
            if (value.result == false) {
              //登录失败
            }
          }).catchError((onError) {
            //登录失败
          });
```

登录成功由异步回调确定
```
FlutterMobileImsdk.setMethodCallHandler(handler: (method) {
      if (method is MobileIMSDKLoginSuccess) {
        //登录成功
      } else if (method is MobileIMSDKLoginFail) {
        //登录失败
      }
    });
```

### 发送消息
```
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
FlutterMobileImsdk.sendMessage(dataContent: '消息内容', toUserId: '接收者id，上面登录方法的userId', qos: true).then((value) {
        if (value.result == false || value.value == false) {
          //消息发送失败
        }
});
```
如果使用qos，则消息是否送达由异步回调确定
```
FlutterMobileImsdk.setMethodCallHandler(handler: (method) {
      if (method is MobileIMSDKRecieveMessage) {
        //收到消息，消息相关内容为method.info
        //消息体包含字段如下
        //String fingerPrint;
        //String userId;
        //String dataContent;
        //int typeu;
      }
    });
```

### 接收消息
```
FlutterMobileImsdk.setMethodCallHandler(handler: (method) {
      if (method is MobileIMSDKMessagesBeReceived) {
        //消息送达，具体判断是哪条消息，由method.fingerPrint确定
      }
    });
```

### 退出登录
```
FlutterMobileImsdk.logout().then((value) {
      if (value.result == true) {
        //退出登录成功
      } else {
        //退出登录失败
      }
    });
```

### debug的时候获取相关线程状态
```
FlutterMobileImsdk.isAutoReLoginRunning().then((value) {
      if (value.result == true) {
        if (value.value == true) {
          //自动登陆线程正在运行
        } else {
          
        }
      }
    });
    FlutterMobileImsdk.isKeepAliveRunning().then((value) {
      if (value.result == true) {
        if (value.value == true) {
          
        } else {
          
        }
      }
    });
    FlutterMobileImsdk.isQoS4SendDaemonRunning().then((value) {
      if (value.result == true) {
        if (value.value == true) {
          
        } else {
          
        }
      }
    });
    FlutterMobileImsdk.isQoS4ReciveDaemonRunning().then((value) {
      if (value.result == true) {
        if (value.value == true) {
          
        } else {
          
        }
      }
    });
```
### FlutterMobileImsdk.setMethodCallHandler
FlutterMobileImsdk.setMethodCallHandler处理的所有异步消息类型如下

```
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
```