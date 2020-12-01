package com.lbx.flutter_mobileimsdk_tcp;

import android.util.Log;

import net.x52im.mobileimsdk.android.ClientCoreSDK;
import net.x52im.mobileimsdk.android.event.ChatBaseEvent;

import java.util.HashMap;

import io.flutter.plugin.common.MethodChannel;

class ChatBaseEventImpl implements ChatBaseEvent
{
    private static final String TAG = "ChatBaseEventImpl";
    final private MethodChannel channel;

    ChatBaseEventImpl(MethodChannel channel) {
        this.channel = channel;
    }

    private HashMap getLoginInfo(){
        HashMap<String,Object> dic = new HashMap<String,Object>();
        dic.put("currentLoginUserId", ClientCoreSDK.getInstance().getCurrentLoginUserId());
        dic.put("currentLoginToken",ClientCoreSDK.getInstance().getCurrentLoginToken());
        dic.put("currentLoginExtra",ClientCoreSDK.getInstance().getCurrentLoginExtra());
        return dic;
    }

    /**
   * 本地用户的登陆结果回调事件通知。
   *
   * @param errorCode 服务端反馈的登录结果：0 表示登陆成功，否则为服务端自定义的出错代码（按照约定通常为>=1025的数）
   */
  @Override
  public void onLoginResponse(int errorCode) {
    if (errorCode == 0)
    {
      Log.i(TAG, "【DEBUG_UI】IM服务器登录/重连成功！");
      channel.invokeMethod("loginSuccess", getLoginInfo());
    }
    else
    {
      Log.e(TAG, "【DEBUG_UI】IM服务器登录/连接失败，错误代码：" + errorCode);
      channel.invokeMethod("loginFail", errorCode);
    }
  }

  /**
   * 与服务端的通信断开的回调事件通知。
   * <br>
   * 该消息只有在客户端连接服务器成功之后网络异常中断之时触发。<br>
   * 导致与与服务端的通信断开的原因有（但不限于）：无线网络信号不稳定、WiFi与2G/3G/4G等同开情况下的网络切换、手机系统的省电策略等。
   *
   * @param errorCode 本回调参数表示表示连接断开的原因，目前错误码没有太多意义，仅作保留字段，目前通常为-1
   */
  @Override
  public void onLinkClose(int errorCode) {
    Log.e(TAG, "【DEBUG_UI】与IM服务器的网络连接出错关闭了，error：" + errorCode);
    channel.invokeMethod("linkClose", errorCode);
  }

}
