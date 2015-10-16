//
//  ViewController.m
//  MyIPsecVPN
//
//  Created by 刘建扬 on 15/10/10.
//  Copyright © 2015年 蜗牛移动. All rights reserved.
//

#import "ViewController.h"
#import "KeyChainHelper.h"
#import <NetworkExtension/NetworkExtension.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *userName;      ////  用户名
@property (weak, nonatomic) IBOutlet UITextField *passWord;      ////  密码
@property (weak, nonatomic) IBOutlet UITextField *serverAddress; ///  服务器IP

@property (weak, nonatomic) IBOutlet UITextField *sharedSecret; ////   共享密钥
@end

@implementation ViewController


//DEBUG
#define ALERT(title,msg) dispatch_async(dispatch_get_main_queue(), ^{UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];[alertController addAction:okAction];[self presentViewController:alertController animated:YES completion:nil];});


//VPN
/*************************************************/

#define kLocalIdentifier @"找服务端要"
#define kRemoteIdentifier @"找服务端要"
/*************************************************/


//Keychain
#define kKeychainServiceName @"com.snail.mobile"
//从Keychain取密码对应的key
#define kPasswordReference @"snail_vpn_key"
#define kSharedSecretReference @"snail_psk_key"



- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(VPNStatusDidChangeNotification) name:NEVPNStatusDidChangeNotification object:nil];
    
    
    
    
}






- (IBAction)pressBtn:(UIButton *)sender {
    
    switch (sender.tag)
    {
        case 0://创建VPN描述文件
        {
            [[NEVPNManager sharedManager] loadFromPreferencesWithCompletionHandler:^(NSError *error){
                if(error)
                {
                    NSLog(@"加载偏好设置失败！！！   Load error: %@", error);
                }
                else
                {
                    //配置IPSec
                    [self setupIPSec];
                    
                    //保存VPN到系统->通用->VPN->个人VPN
                    [[NEVPNManager sharedManager] saveToPreferencesWithCompletionHandler:^(NSError *error){
                        if(error)
                        {
                            ALERT(@"保存VPN配置信息失败", error.description);
                            NSLog(@"保存VPN配置信息失败！Save error: %@", error);
                        }
                        else
                        {
                            NSLog(@"Saved!");
                            ALERT(@"Saved", @"保存VPN配置信息 Success！！");
                        }
                    }];
                }
            }];
            break;
        }
        case 1://TODO:删除VPN描述文件
        {
            [[NEVPNManager sharedManager] loadFromPreferencesWithCompletionHandler:^(NSError *error){
                if (!error)
                {
                    [[NEVPNManager sharedManager] removeFromPreferencesWithCompletionHandler:^(NSError *error){
                        if(error)
                        {
                            NSLog(@"Remove error: %@", error);
                            ALERT(@"removeFromPreferences", error.description);
                        }
                        else
                        {
                            ALERT(@"removeFromPreferences", @"删除成功");
                        }
                    }];
                }else{
                    NSLog(@"加载偏好设置失败！！！   Load error: %@", error);
                }
            }];
            
            break;
        }
        case 2://TODO:连接VPN(前提是必须有描述文件)
        {
            [[NEVPNManager sharedManager] loadFromPreferencesWithCompletionHandler:^(NSError *error){
                if (!error)
                {
                    //配置IPSec
                    [self setupIPSec];
                    
                    [[NEVPNManager sharedManager].connection startVPNTunnelAndReturnError:&error];
                }else{
                    NSLog(@"加载偏好设置失败！！！   Load error: %@", error);
                }
            }];
            break;
        }
        case 3://TODO:断开VPN
        {
            [[NEVPNManager sharedManager] loadFromPreferencesWithCompletionHandler:^(NSError *error){
                if (!error)
                {
                    [[NEVPNManager sharedManager].connection stopVPNTunnel];
                }else{
                    NSLog(@"加载偏好设置失败！！！   Load error: %@", error);
                }
            }];
            break;
        }
            
        default:
            break;
    }

    
}











#pragma mark - IPSec
- (void)setupIPSec
{
    
    
    NSString *username = self.userName.text;
    NSString *password = self.passWord.text;
    NSString *serverAddress = self.serverAddress.text;
    NSString *psk = self.sharedSecret.text;
    
    
    
    
    
    ////  将 VPN的密码 存储到 钥匙串中去
    
    [KeyChainHelper saveValue:password andKey:kPasswordReference toService:kKeychainServiceName];
    [KeyChainHelper saveValue:psk andKey:kSharedSecretReference toService:kKeychainServiceName];
    
    
    
    
    NEVPNProtocolIPSec *p = [[NEVPNProtocolIPSec alloc] init];
    p.username = username;
    p.passwordReference = [KeyChainHelper getDataByKey:kPasswordReference fromService:kKeychainServiceName];
    p.serverAddress = serverAddress;
    
    p.authenticationMethod = NEVPNIKEAuthenticationMethodSharedSecret;
    p.sharedSecretReference = [KeyChainHelper getDataByKey:kSharedSecretReference fromService:kKeychainServiceName];
    p.disconnectOnSleep = NO;
    

    /**
     *  IKE 的协商模式
     *  IKE 第一阶段的协商可以采用两种模式：主模式（Main Mode ）和野蛮模式（Aggressive Mode ）
     
     1、野蛮模式协商比主模式协商更快。主模式需要交互6个消息，野蛮模式只需要交互3个消息。
     2、主模式协商比野蛮模式协商更严谨、更安全。因为主模式在5、6个消息中对ID信息进行了加密。而野蛮模式由于受到交换次数的限制，ID信息在1、2个消息中以明文的方式发送给对端。即主模式对对端身份进行了保护，而野蛮模式则没有。
     3、两种模式在确定预共享密钥的方式不同。主模式只能基于IP地址来确定预共享密钥。而积极模式是基于ID信息（主机名和IP地址）来确定预共享密钥。
     
     *  两边都是主机名的时候，就一定要用野蛮模式来协商，如果用主模式的话，就会出现根据源IP地址找不到预共享密钥的情况，以至于不能生成SKEYID。
     
     *  这两个值设置后是野蛮模式（Aggressive Mode）不设置是主模式（Main Mode)   根据后台需要进行设置
     */
    p.localIdentifier = @"ipsec";
    p.remoteIdentifier = @"ipsec";
    
    
    
    /**
     *
     *  是否需要扩展鉴定(群组)
     *  如果为YES   就需要设置 localIdentifier 和  remoteIdentifier
     */
    p.useExtendedAuthentication = YES;
    
    
    
    [[NEVPNManager sharedManager] setProtocolConfiguration:p];
    [[NEVPNManager sharedManager] setOnDemandEnabled:NO];
    [[NEVPNManager sharedManager] setLocalizedDescription:@"蜗牛移动VPN"];//VPN自定义名字
    [[NEVPNManager sharedManager] setEnabled:YES];
    
    
    
}






#pragma mark - VPN状态切换通知
- (void)VPNStatusDidChangeNotification
{
    switch ([NEVPNManager sharedManager].connection.status)
    {
        case NEVPNStatusInvalid:
        {
            NSLog(@"NEVPNStatusInvalid  状态不合法");
            break;
        }
        case NEVPNStatusDisconnected:
        {
            NSLog(@"NEVPNStatusDisconnected  断开");
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            break;
        }
        case NEVPNStatusConnecting:
        {
            NSLog(@"NEVPNStatusConnecting   正在连接....");
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            break;
        }
        case NEVPNStatusConnected:
        {
            NSLog(@"NEVPNStatusConnected    已经连接....");
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            break;
        }
        case NEVPNStatusReasserting:
        {
            NSLog(@"NEVPNStatusReasserting  重连中....");
            break;
        }
        case NEVPNStatusDisconnecting:
        {
            NSLog(@"NEVPNStatusDisconnecting     正在断开...");
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            break;
        }
        default:
            break;
    }
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {


    [self.view endEditing:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
