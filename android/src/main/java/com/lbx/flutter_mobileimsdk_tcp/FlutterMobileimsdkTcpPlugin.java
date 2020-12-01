package com.lbx.flutter_mobileimsdk_tcp;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.os.AsyncTask;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

import net.x52im.mobileimsdk.android.ClientCoreSDK;
import net.x52im.mobileimsdk.android.conf.ConfigEntity;
import net.x52im.mobileimsdk.android.core.AutoReLoginDaemon;
import net.x52im.mobileimsdk.android.core.KeepAliveDaemon;
import net.x52im.mobileimsdk.android.core.LocalDataSender;
import net.x52im.mobileimsdk.android.core.QoS4ReciveDaemon;
import net.x52im.mobileimsdk.android.core.QoS4SendDaemon;

import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.Map;
import java.util.Observer;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlutterMobileimsdkTcpPlugin */
public class FlutterMobileimsdkTcpPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  /** MobileIMSDK是否已被初始化. true表示已初化完成，否则未初始化. */
  private boolean init = false;

  private Context context;

  private static final String TAG = "MobileimsdkTcpPlugin";

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_mobileimsdk_tcp");
    channel.setMethodCallHandler(this);
    context = flutterPluginBinding.getApplicationContext();
  }

  private  HashMap getLoginInfo(){
    HashMap<String,Object> dic = new HashMap<String,Object>();
    dic.put("currentLoginUserId",ClientCoreSDK.getInstance().getCurrentLoginUserId());
    dic.put("currentLoginToken",ClientCoreSDK.getInstance().getCurrentLoginToken());
    dic.put("currentLoginExtra",ClientCoreSDK.getInstance().getCurrentLoginExtra());
    return dic;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "initMobileIMSDK":{
        initMobileIMSDK(call,result);
        break;
      }
      case "login":{
        login(call,result);
        break;
      }
      case "sendMessage":{
        sendMessage(call,result);
        break;
      }
      case "logout":{
        logout(call,result);
        break;
      }
      case "getConnectedStatus":{
        getConnectedStatus(call,result);
        break;
      }
      case "getCurrentLoginInfo":{
        getCurrentLoginInfo(call,result);
        break;
      }
      case "isAutoReLoginRunning":{
        isAutoReLoginRunning(call,result);
        break;
      }
      case "isKeepAliveRunning":{
        isKeepAliveRunning(call,result);
        break;
      }
      case "isQoS4SendDaemonRunning":{
        isQoS4SendDaemonRunning(call,result);
        break;
      }
      case "isQoS4ReciveDaemonRunning":{
        isQoS4ReciveDaemonRunning(call,result);
        break;
      }
      default:
        result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    // 释放IM占用资源
    ClientCoreSDK.getInstance().release();
  }

  // 确保MobileIMSDK被初始化哦（整个APP生生命周期中只需调用一次哦）
	// 提示：在不退出APP的情况下退出登陆后再重新登陆时，请确保调用本方法一次，不然会报code=203错误哦！
  private void initMobileIMSDK(@NonNull MethodCall call,@NonNull Result result)
  {
    if(!init) {
      if (call.arguments instanceof Map) {
        Map<Object, Object> dic = (Map) call.arguments;
        String serverIP = (String) dic.get("serverIP");
        Integer serverPort = (Integer) dic.get("serverPort");
        Integer senseMode = (Integer) dic.get("senseMode");
        Boolean debug = (Boolean) dic.get("debug");
        String appKey = (String) dic.get("appKey");
        if (serverIP != null && serverPort != null) {
          init = true;
          ConfigEntity.serverIP = serverIP;
          ConfigEntity.serverPort = serverPort;

          ClientCoreSDK.DEBUG = debug == Boolean.TRUE;
          if(ClientCoreSDK.DEBUG) {
            AutoReLoginDaemon.getInstance().setDebugObserver(
                    createObserverCompletionForDEBUG("AutoReLoginDaemonObserver"));
            KeepAliveDaemon.getInstance().setDebugObserver(
                    createObserverCompletionForDEBUG("KeepAliveDaemonObserver"));
            QoS4SendDaemon.getInstance().setDebugObserver(
                    createObserverCompletionForDEBUG("QoS4SendDaemonObserver"));
            QoS4ReciveDaemon.getInstance().setDebugObserver(
                    createObserverCompletionForDEBUG("QoS4ReciveDaemonObserver"));
          }
          if (senseMode != null && senseMode < ConfigEntity.SenseMode.values().length) {
            ConfigEntity.setSenseMode(ConfigEntity.SenseMode.values()[senseMode]);
          }
          if(appKey != null) {
            // 设置AppKey
            ConfigEntity.appKey = appKey;
          }
          // 【特别注意】请确保首先进行核心库的初始化（这是不同于iOS和Java端的地方)
          ClientCoreSDK.getInstance().init(this.context);

          ClientCoreSDK.getInstance().setChatBaseEvent(new ChatBaseEventImpl(channel));
          ClientCoreSDK.getInstance().setChatMessageEvent(new ChatMessageEventImpl(channel));
          ClientCoreSDK.getInstance().setMessageQoSEvent(new MessageQoSEventImpl(channel));

          HashMap<String, Object> resultDic = new HashMap<>();
          resultDic.put("result", Boolean.TRUE);
          result.success(resultDic);
          return;
        }
      }
      HashMap<String, Object> resultDic = new HashMap<>();
      resultDic.put("result", Boolean.FALSE);
      result.success(resultDic);
    }
  }

  private Observer createObserverCompletionForDEBUG(@NonNull final String methodName)
  {
    final WeakReference<FlutterMobileimsdkTcpPlugin> weakSelf = new WeakReference<>(this);
    return (o, arg) -> {
      if(arg != null) {
        final int status = (int) arg;
        if(weakSelf.get() != null) {
          Handler mainHandler = new Handler(Looper.getMainLooper());
          mainHandler.post(new Runnable() {
            @Override
            public void run() {
              //已在主线程中，可以更新UI
              weakSelf.get().channel.invokeMethod(methodName,status);
            }
          });
        }
      }
    };
  }

  @SuppressLint("StaticFieldLeak")
  private void login(@NonNull MethodCall call, @NonNull final Result result) {
    if(call.arguments instanceof Map) {
      Map dic = (Map) call.arguments;
      String loginUserId = (String) dic.get("loginUserId");
      String loginToken = (String) dic.get("loginToken");
      String extra = (String) dic.get("extra");

      if (loginUserId != null && loginToken != null) {
        // * 发送登陆数据包(提交登陆名和密码)
        new LocalDataSender.SendLoginDataAsync(loginUserId, loginToken, extra) {
          /**
           * 登陆信息发送完成后将调用本方法（注意：此处仅是登陆信息发送完成
           * ，真正的登陆结果要在异步回调中处理哦）。
           *
           * @param code 数据发送返回码，0 表示数据成功发出，否则是错误码
           */
          @Override
          protected void fireAfterSendLogin(int code) {
            HashMap<String, Object> resultDic = new HashMap<String, Object>();
            if (code == 0) {
              Log.d(TAG, "登陆/连接信息已成功发出！");
              resultDic.put("result", Boolean.TRUE);
            } else {
              Log.d(TAG, "登陆/连接信息发送失败！");
              resultDic.put("result", Boolean.FALSE);
            }
            result.success(resultDic);
          }
        }.execute();
        return;
      }
    }
      HashMap<String,Object> resultDic = new HashMap<>();
      resultDic.put("result", Boolean.FALSE);
      result.success(resultDic);

  }

  @SuppressLint("StaticFieldLeak")
  private void logout(@NonNull MethodCall call, @NonNull final Result result) {
    final WeakReference<FlutterMobileimsdkTcpPlugin> weakSelf = new WeakReference<>(this);
    // 发出退出登陆请求包（Android系统要求必须要在独立的线程中发送哦）
    new AsyncTask<Object, Integer, Integer>(){
      @Override
      protected Integer doInBackground(Object... params)
      {
        int code = -1;
        try{
          code = LocalDataSender.getInstance().sendLoginout();
        }
        catch (Exception e){
          Log.w(TAG, e);
        }

        //## BUG FIX: 20170713 START by JackJiang
        // 退出登陆时记得一定要调用此行，不然不退出APP的情况下再登陆时会报 code=203错误哦！
        if(weakSelf.get() != null) {
          weakSelf.get().init = false;
        }
        //## BUG FIX: 20170713 END by JackJiang

        return code;
      }

      @Override
      protected void onPostExecute(Integer code)
      {
        HashMap<String,Object> resultDic = new HashMap<String,Object>();
        if(code == 0)
          resultDic.put("result", Boolean.TRUE);
        else {
          resultDic.put("result", Boolean.FALSE);
        }
        resultDic.put("value", code);
        result.success(resultDic);
      }
    }.execute();
  }

  @SuppressLint("StaticFieldLeak")
  private void sendMessage(@NonNull MethodCall call, @NonNull final Result result) {
    if(call.arguments instanceof Map) {
      Map dic = (Map) call.arguments;
      final String dataContent = (String) dic.get("dataContent");
      final String toUserId = (String) dic.get("toUserId");
      final String fingerPrint = (String) dic.get("fingerPrint");
      final Boolean qos = (Boolean) dic.get("qos");
      final Integer typeu = (Integer) dic.get("typeu");
      if (dataContent != null && toUserId != null) {
        // 发送消息（Android系统要求必须要在独立的线程中发送哦）
        new AsyncTask<Object, Integer, Integer>() {
          @Override
          protected Integer doInBackground(Object... params) {
            int code = LocalDataSender.getInstance().sendCommonData(dataContent, toUserId, qos == true, fingerPrint, typeu == null ? -1 : typeu);
            return code;
          }

          @Override
          protected void onPostExecute(Integer code) {
            HashMap<String, Object> resultDic = new HashMap<>();
            if (code == 0) {
              resultDic.put("result", Boolean.TRUE);
            } else {
              resultDic.put("result", Boolean.FALSE);
            }
            result.success(resultDic);
          }
        }.execute();
        return;
      }
    }

      HashMap<String,Object> resultDic = new HashMap<>();
      resultDic.put("result", Boolean.FALSE);
      result.success(resultDic);
  }

  private void getConnectedStatus(@NonNull MethodCall call,@NonNull Result result) {
    // 获取与服务器连接状态
    HashMap<String,Object> dic = new HashMap<>();
    dic.put("result", Boolean.TRUE);
    dic.put("value", ClientCoreSDK.getInstance().isConnectedToServer());
    result.success(dic);
  }

  private void getCurrentLoginInfo(@NonNull MethodCall call,@NonNull Result result) {
    // 获取当前登录信息
    HashMap<String,Object> dic = new HashMap<>();
    dic.put("result", ClientCoreSDK.getInstance().getCurrentLoginUserId() != null && ClientCoreSDK.getInstance().getCurrentLoginToken() != null);
    dic.put("value", getLoginInfo());
    result.success(dic);
  }

  private void isAutoReLoginRunning(@NonNull MethodCall call,@NonNull Result result) {
    // 自动登录重连是否正在运行
    HashMap<String,Object> dic = new HashMap<>();
    dic.put("result", Boolean.TRUE);
    dic.put("value", AutoReLoginDaemon.getInstance().isAutoReLoginRunning());
    result.success(dic);
  }

  private void isKeepAliveRunning(@NonNull MethodCall call,@NonNull Result result) {
    // keepAlive是否正在运行
    HashMap<String,Object> dic = new HashMap<>();
    dic.put("result", Boolean.TRUE);
    dic.put("value", KeepAliveDaemon.getInstance().isKeepAliveRunning());
    result.success(dic);
  }

  private void isQoS4SendDaemonRunning(@NonNull MethodCall call,@NonNull Result result) {
    // QoS4SendDaemon是否正在运行
    HashMap<String,Object> dic = new HashMap<>();
    dic.put("result", Boolean.TRUE);
    dic.put("value", QoS4SendDaemon.getInstance().isRunning());
    result.success(dic);
  }

  private void isQoS4ReciveDaemonRunning(@NonNull MethodCall call,@NonNull Result result) {
    // QoS4ReciveDaemon是否正在运行
    HashMap<String,Object> dic = new HashMap<>();
    dic.put("result", Boolean.TRUE);
    dic.put("value", QoS4ReciveDaemon.getInstance().isRunning());
    result.success(dic);
  }
}
