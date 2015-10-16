//
//  KeyChainHelper.m
//  sss
//
//  Created by 刘建扬 on 15/8/27.
//  Copyright (c) 2015年 医健行. All rights reserved.
//

#import "KeyChainHelper.h"

@implementation KeyChainHelper

+ (NSMutableDictionary *)getKeyChainQueryFromService:(NSString *)service andKey:(NSString *)key {
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)kSecClassGenericPassword,(__bridge id)kSecClass,
            service, (__bridge id)kSecAttrService,  ///CFStringRef
            key, (__bridge id)kSecAttrAccount,  ///CGStringRef
            [key dataUsingEncoding:NSUTF8StringEncoding],(__bridge id)kSecAttrGeneric, ///CFDataRef
            (__bridge id)kSecAttrAccessibleAlwaysThisDeviceOnly,(__bridge id)kSecAttrAccessible,
            nil];
}


+ (void)saveValue:(NSString *)value andKey:(NSString *)key toService:(NSString *)service {
    
    NSMutableDictionary * dict = [self getKeyChainQueryFromService:service andKey:key];
    ///  先去执行删除操作
    SecItemDelete((__bridge CFDictionaryRef)dict);
    [dict setObject:[value dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
    
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dict, NULL);
    if(errSecSuccess != status) {
        NSLog(@"保存%@的值失败，错误代码 error:%d",key,(int)status);
    }else{
        NSLog(@"保存成功");
    }
}

+ (NSData *)getDataByKey:(NSString *)key fromService:(NSString *)service {
    
    NSMutableDictionary * dict = [self getKeyChainQueryFromService:service andKey:key];
    [dict setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnPersistentRef]; // The most important part,确保持久引用
    
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)dict,&result);
    
    if( status != errSecSuccess) {
        NSLog(@"获取%@的值失败！错误代码 error:%d",key,(int)status);
        return nil;
    }else{
        NSLog(@"获取成功！");
    }
    
    return (__bridge_transfer NSData *)result;
}
@end
