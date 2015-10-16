//
//  KeyChainHelper.h
//  sss
//
//  Created by 刘建扬 on 15/8/27.
//  Copyright (c) 2015年 医健行. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyChainHelper : NSObject

/**
 *  @author liujianyang
 *
 *  @brief  <#Description#>
 *
 *  @param value   <#value description#>
 *  @param key     <#key description#>
 *  @param service <#service description#>
 *
 *  @since <#version number#>
 */
+ (void) saveValue:(NSString *) value andKey:(NSString *) key toService:(NSString *)service;

/**
 *  @author liujianyang
 *
 *  @brief  <#Description#>
 *
 *  @param key     <#key description#>
 *  @param service <#service description#>
 *
 *  @return <#return value description#>
 *
 *  @since <#1.00#>
 */
+ (NSData *) getDataByKey:(NSString *)key fromService:(NSString *)service;

@end
