#import "FlutterMobileimsdkTcpPlugin.h"
#import "ClientCoreSDK.h"
#import "ConfigEntity.h"
#import "LocalDataSender.h"
#import "AutoReLoginDaemon.h"
#import "KeepAliveDaemon.h"
#import "QoS4ReciveDaemon.h"
#import "QoS4SendDaemon.h"
#import "NSMutableDictionary+Ext.h"
#import "ChatBaseEvent.h"
#import "ChatMessageEvent.h"
#import "MessageQoSEvent.h"
@interface FlutterMobileimsdkTcpPlugin()<MessageQoSEvent,ChatMessageEvent,ChatBaseEvent>
/* MobileIMSDK是否已被初始化. true表示已初化完成，否则未初始化. */
@property (nonatomic) BOOL _init;
/* 收到服务端的登陆完成反馈时要通知的观察者（因登陆是异步实现，本观察者将由
 *  ChatBaseEvent 事件的处理者在收到服务端的登陆反馈后通知之）*/
@property (nonatomic, copy) ObserverCompletion onLoginSucessObserver;// block代码块一定要用copy属性，否则报错！
@property (nonatomic,strong) FlutterMethodChannel *channel;

@end

@implementation FlutterMobileimsdkTcpPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_mobileimsdk_tcp"
            binaryMessenger:[registrar messenger]];
  FlutterMobileimsdkTcpPlugin* instance = [[FlutterMobileimsdkTcpPlugin alloc] init];
  instance.channel = channel;
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (NSDictionary *)getLoginInfo {
    NSMutableDictionary *argument = [NSMutableDictionary new];
    [self addObjectForDic:argument key:@"currentLoginUserId" value:[ClientCoreSDK sharedInstance].currentLoginUserId];
    [self addObjectForDic:argument key:@"currentLoginToken" value:[ClientCoreSDK sharedInstance].currentLoginToken];
    [self addObjectForDic:argument key:@"currentLoginExtra" value:[ClientCoreSDK sharedInstance].currentLoginExtra];
    return argument;
}

- (void)addObjectForDic:(NSMutableDictionary *)dic key:(NSString *)key value:(NSObject *)value {
    if(value != nil) {
        dic[key] = value;
    }
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
      if([call.method isEqualToString:@"initMobileIMSDK"]) {
          [self initMobileIMSDK:call result:result];
      }
      else if ([call.method isEqualToString:@"login"]){
          [self login:call result:result];
      }
      else if([call.method isEqualToString:@"sendMessage"]) {
          [self sendMessage:call result:result];
      }
      else if([call.method isEqualToString:@"logout"]){
          [self logout:call result:result];
      }
      else if([call.method isEqualToString:@"getConnectedStatus"]){
          [self getConnectedStatus:call result:result];
      }
      else if([call.method isEqualToString:@"getCurrentLoginInfo"]) {
          [self getCurrentLoginInfo:call result:result];
      }
      else if([call.method isEqualToString:@"isAutoReLoginRunning"]) {
          [self isAutoReLoginRunning:call result:result];
      }
      else if([call.method isEqualToString:@"isKeepAliveRunning"]) {
          [self isKeepAliveRunning:call result:result];
      }
      else if([call.method isEqualToString:@"isQoS4SendDaemonRunning"]) {
          [self isQoS4SendDaemonRunning:call result:result];
      }
      else if([call.method isEqualToString:@"isQoS4ReciveDaemonRunning"]) {
          [self isQoS4ReciveDaemonRunning:call result:result];
      }
      else {
          result(FlutterMethodNotImplemented);
      }
}

// 确保MobileIMSDK被初始化哦（整个APP生生命周期中只需调用一次哦）
	// 提示：在不退出APP的情况下退出登陆后再重新登陆时，请确保调用本方法一次，不然会报code=203错误哦！
- (void)initMobileIMSDK:(FlutterMethodCall*)call result:(FlutterResult)result 
{
    if(!self._init && [call.arguments isKindOfClass:NSDictionary.class])
    {
        NSDictionary *dic = call.arguments;
        NSString *serverIP = dic[@"serverIP"];
        NSNumber *serverPort = dic[@"serverPort"];
        
        
        if (serverIP != nil && [serverPort isKindOfClass:[NSNumber class]]) {
            // 设置服务器ip和服务器端口
          [ConfigEntity setServerIp:serverIP];
          [ConfigEntity setServerPort:[serverPort intValue]];
            result(@{@"result":@YES});
        }
        else {
            result(@{@"result":@NO});
        }
       
        if([[dic allKeys] containsObject:@"senseMode"]) {
            // RainbowCore核心IM框架的敏感度模式设置
          [ConfigEntity setSenseMode:[dic[@"senseMode"] intValue]];
        }
        
        if([[dic allKeys] containsObject:@"debug"]) {
            // 开启DEBUG信息输出
            bool debug = [dic[@"debug"] boolValue];
            if (debug) {
                [[AutoReLoginDaemon sharedInstance] setDebugObserver:[self createObserverCompletionFor:@"AutoReLoginDaemonObserver"]];
                [[KeepAliveDaemon sharedInstance] setDebugObserver:[self createObserverCompletionFor:@"KeepAliveDaemonObserver"]];
                [[QoS4SendDaemon sharedInstance] setDebugObserver:[self createObserverCompletionFor:@"QoS4SendDaemonObserver"]];
                [[QoS4ReciveDaemon sharedInstance] setDebugObserver:[self createObserverCompletionFor:@"QoS4ReciveDaemonObserver"]];
            }
          [ClientCoreSDK setENABLED_DEBUG:debug];
        }
        
        if([[dic allKeys] containsObject:@"appKey"]) {
            NSString *appKey = dic[@"appKey"];
            // 设置AppKey
            [ConfigEntity registerWithAppKey:appKey];
        }
        
        
        // 设置事件回调
      
        [ClientCoreSDK sharedInstance].chatBaseEvent = self;
        [ClientCoreSDK sharedInstance].chatMessageEvent = self;
        [ClientCoreSDK sharedInstance].messageQoSEvent = self;
        
        self._init = YES;
    }
    else {
        result(@{@"result":@NO});
    }
}

- (ObserverCompletion) createObserverCompletionFor:(NSString *)channelMethod
{
    __weak __typeof(self) weakSelf = self;
    ObserverCompletion clp = ^(id observerble ,id data) {
        int status = [(NSNumber *)data intValue];
        [weakSelf.channel invokeMethod:channelMethod arguments:[NSNumber numberWithInt:status]];
    };
    
    return clp;
}

- (void)login:(FlutterMethodCall*)call result:(FlutterResult)result {
    if([call.arguments isKindOfClass:NSDictionary.class]) {
        NSDictionary *dic = call.arguments;
        NSString *loginUserId = dic[@"loginUserId"];
        NSString *loginToken = dic[@"loginToken"];
        NSString *extra = [dic.allKeys containsObject:@"extra"] ? dic[@"extra"] : nil;
        
        if(loginUserId != nil && loginToken != nil) {
            // * 发送登陆数据包(提交登陆名和密码)
            int code = [[LocalDataSender sharedInstance] sendLogin:loginUserId withToken:loginToken andExtra:extra];
           
            if(code == COMMON_CODE_OK)
            {
                result(@{@"result":@YES});
            }
            else
            {
                result(@{@"result":@NO});
            }
        }
        else {
            result(@{@"result":@NO});
        }
    }
    else {
        result(@{@"result":@NO});
    }    
}

- (void)logout:(FlutterMethodCall*)call result:(FlutterResult)result {
    // 发出退出登陆请求包
    int code = [[LocalDataSender sharedInstance] sendLoginout];
    if(code == COMMON_CODE_OK)
    {
        result(@{@"result":@YES,@"value":[NSNumber numberWithInt:code]});
    }
    else
    {
        result(@{@"result":@NO,@"value":[NSNumber numberWithInt:code]});
    }  
    self._init = NO;
}

- (void)sendMessage:(FlutterMethodCall*)call result:(FlutterResult)result {
    if([call.arguments isKindOfClass:NSDictionary.class]) {
        NSDictionary *dic = call.arguments;
        NSString *dataContent = dic[@"dataContent"];
        NSString *toUserId = dic[@"toUserId"];
        
        NSString *fingerPrint = [dic.allKeys containsObject:@"fingerPrint"] ? dic[@"fingerPrint"] : nil;
        bool qos = [dic.allKeys containsObject:@"qos"]?[dic[@"qos"] boolValue]:NO;
        int typeu = [dic.allKeys containsObject:@"typeu"]?[dic[@"typeu"] intValue]:-1;
        
        if(dataContent != nil && toUserId != nil) {
            // * 发送登陆数据包(提交登陆名和密码)
            int code = [[LocalDataSender sharedInstance] sendCommonDataWithStr:dataContent toUserId:toUserId qos:qos fp:fingerPrint withTypeu:typeu];
           
            if(code == COMMON_CODE_OK)
            {
                result(@{@"result":@YES});
            }
            else
            {
                result(@{@"result":@NO});
            }
        }
        else {
            result(@{@"result":@NO});
        }
    }
    else {
        result(@{@"result":@NO});
    }    
}

- (void)getConnectedStatus:(FlutterMethodCall*)call result:(FlutterResult)result {
    // 获取与服务器连接状态
    result(@{@"result":@YES, @"value":@([ClientCoreSDK sharedInstance].connectedToServer)});
}

- (void)getCurrentLoginInfo:(FlutterMethodCall*)call result:(FlutterResult)result {
    // 获取当前登录信息
    if([ClientCoreSDK sharedInstance].currentLoginUserId != nil && [ClientCoreSDK sharedInstance].currentLoginToken != nil) {
        result(@{@"result":@YES,@"value":[self getLoginInfo]});
    }
    else {
        result(@{@"result":@NO});
    }
}

- (void)isAutoReLoginRunning:(FlutterMethodCall*)call result:(FlutterResult)result {
    // 自动登录重连是否正在运行
    result(@{@"result":@YES, @"value":@([[AutoReLoginDaemon sharedInstance] isAutoReLoginRunning])});
}

- (void)isKeepAliveRunning:(FlutterMethodCall*)call result:(FlutterResult)result {
    // keepAlive是否正在运行
    result(@{@"result":@YES, @"value":@([[KeepAliveDaemon sharedInstance] isKeepAliveRunning])});
}

- (void)isQoS4SendDaemonRunning:(FlutterMethodCall*)call result:(FlutterResult)result {
    // QoS4SendDaemon是否正在运行
    result(@{@"result":@YES, @"value":@([[QoS4SendDaemon sharedInstance] isRunning])});
}

- (void)isQoS4ReciveDaemonRunning:(FlutterMethodCall*)call result:(FlutterResult)result {
    // QoS4ReciveDaemon是否正在运行
    result(@{@"result":@YES, @"value":@([[QoS4ReciveDaemon sharedInstance] isRunning])});
}
    
#pragma mark - ChatBaseEvent
    /*!
     * 本地用户的登陆结果回调事件通知。
     *
     * @param errorCode 服务端反馈的登录结果：0 表示登陆成功，否则为服务端自定义的出错代码（按照约定通常为>=1025的数）
     */
    - (void)onLoginResponse:(int)errorCode
    {
        if (errorCode == 0)
        {
            NSLog(@"【DEBUG_UI】IM服务器登录/连接成功！");
            [self.channel invokeMethod:@"loginSuccess" arguments:[self getLoginInfo]];
        }
        else
        {
            NSLog(@"【DEBUG_UI】IM服务器登录/连接失败，错误代码：%d", errorCode);
            [self.channel invokeMethod:@"loginFail" arguments:[NSNumber numberWithInt:errorCode]];
        }
    }

    /*!
     * 与服务端的通信断开的回调事件通知。
     *
     * <br>
     * 该消息只有在客户端连接服务器成功之后网络异常中断之时触发。
     * 导致与与服务端的通信断开的原因有（但不限于）：无线网络信号不稳定、WiFi与2G/3G/4G等同开情
     * 况下的网络切换、手机系统的省电策略等。
     *
     * @param errorCode 本回调参数表示表示连接断开的原因，目前错误码没有太多意义，仅作保留字段，目前通常为-1
     */
    - (void) onLinkClose:(int)errorCode
    {
        NSLog(@"【DEBUG_UI】与IM服务器的网络连接出错关闭了，error：%d", errorCode);
        [self.channel invokeMethod:@"linkClose" arguments:[NSNumber numberWithInt:errorCode]];
    }

#pragma mark - ChatMessageEvent

/*!
 * 收到普通消息的回调事件通知。
 * <br>
 * 应用层可以将此消息进一步按自已的IM协议进行定义，从而实现完整的即时通信软件逻辑。
 *
 * @param fingerPrintOfProtocal 当该消息需要QoS支持时本回调参数为该消息的特征指纹码，否则为null
 * @param userid 消息的发送者id（RainbowCore框架中规定发送者id=“0”即表示是由服务端主动发过的，否则表示的是其它客户端发过来的消息）
 * @param dataContent 消息内容的文本表示形式
 */
- (void) onRecieveMessage:(NSString *)fingerPrintOfProtocal withUserId:(NSString *)userid andContent:(NSString *)dataContent andTypeu:(int)typeu
{
    NSLog(@"【DEBUG_UI】[%d]收到来自用户%@的消息:%@", typeu, userid, dataContent);
    [self.channel invokeMethod:@"onRecieveMessage" arguments:@{@"fingerPrint":fingerPrintOfProtocal,@"userId":userid,@"dataContent":dataContent,@"typeu":[NSNumber numberWithInt:typeu]}];
}

/*!
 * 服务端反馈的出错信息回调事件通知。
 *
 * @param errorCode 错误码，定义在常量表 ErrorCode 中有关服务端错误码的定义
 * @param errorMsg 描述错误内容的文本信息
 * @see ErrorCode
 */
- (void) onErrorResponse:(int)errorCode withErrorMsg:(NSString *)errorMsg
{
    NSLog(@"【DEBUG_UI】收到服务端错误消息，errorCode=%d, errorMsg=%@", errorCode, errorMsg);
    [self.channel invokeMethod:@"onErrorResponse" arguments:@{@"errorMsg":errorMsg,@"errorCode":[NSNumber numberWithInt:errorCode],@"isUnlogin":@(errorCode == ForS_RESPONSE_FOR_UNLOGIN)}];
}

#pragma mark - MessageQoSEvent

/*!
 * 消息未送达的回调事件通知.
 *
 * @param lostMessages 由MobileIMSDK QoS算法判定出来的未送达消息列表（此列表
 * 中的Protocal对象是原对象的clone（即原对象的深拷贝），请放心使用哦），应用层
 * 可通过指纹特征码找到原消息并可以UI上将其标记为”发送失败“以便即时告之用户
 */
- (void) messagesLost:(NSMutableArray*)lostMessages
{
    NSLog(@"【DEBUG_UI】收到系统的未实时送达事件通知，当前共有%li个包QoS保证机制结束，判定为【无法实时送达】！", (unsigned long)[lostMessages count]);
    NSMutableArray *lostArray = [NSMutableArray new];
    for (id item in lostMessages) {
        if([item isKindOfClass:Protocal.class]) {
            Protocal *protocal = item;
            NSMutableDictionary *dic = [NSMutableDictionary new];
            [self addObjectForDic:dic key:@"bridge" value:@(protocal.bridge)];
            [self addObjectForDic:dic key:@"type" value:@(protocal.type)];
            [self addObjectForDic:dic key:@"dataContent" value:protocal.dataContent];
            [self addObjectForDic:dic key:@"from" value:protocal.from];
            [self addObjectForDic:dic key:@"to" value:protocal.to];
            [self addObjectForDic:dic key:@"fp" value:protocal.fp];
            [self addObjectForDic:dic key:@"QoS" value:@(protocal.QoS)];
            [self addObjectForDic:dic key:@"typeu" value:@(protocal.typeu)];
            [lostArray addObject:dic];
        }
    }
    [self.channel invokeMethod:@"qosMessagesLost" arguments:lostArray];
}

/*!
 * 消息已被对方收到的回调事件通知.
 * <p>
 * <b>目前，判定消息被对方收到是有两种可能：</b>
 * <br>
 * 1) 对方确实是在线并且实时收到了；<br>
 * 2) 对方不在线或者服务端转发过程中出错了，由服务端进行离线存储成功后的反馈
 * （此种情况严格来讲不能算是“已被收到”，但对于应用层来说，离线存储了的消息
 * 原则上就是已送达了的消息：因为用户下次登陆时肯定能通过HTTP协议取到）。
 *
 * @param theFingerPrint 已被收到的消息的指纹特征码（唯一ID），应用层可据此ID
 * 来找到原先已发生的消息并可在UI是将其标记为”已送达“或”已读“以便提升用户体验
 */
- (void) messagesBeReceived:(NSString *)theFingerPrint
{
    if(theFingerPrint != nil)
    {
        NSLog(@"【DEBUG_UI】收到对方已收到消息事件的通知，fp=%@", theFingerPrint);
        [self.channel invokeMethod:@"qosMessagesBeReceived" arguments:theFingerPrint];
    }
}

@end
