//
//  UIDevice+UUID.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 05.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (GGUUID)

- (NSString *)gg_UUID;
- (NSString *)gg_macAddress;

@end
