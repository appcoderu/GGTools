//
//  GGNetworkActivityIndicator.m
//	GGFramework
//
//  Created by Evgeniy Shurakov on 10.06.12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import "GGNetworkActivityIndicator.h"
#import <UIKit/UIKit.h>

@implementation GGNetworkActivityIndicator

+ (void)setNetworkActivityIndicatorVisible:(BOOL)visible {
	static dispatch_queue_t queue = nil;
	static NSInteger networkActivityIndicatorVisibleCounter = 0;
	
	if (!queue) {
		queue = dispatch_queue_create("ru.appcode.indicatorQueue", 0);
	}

	dispatch_sync(queue, ^{
		if(visible) {
			networkActivityIndicatorVisibleCounter++;
			if(networkActivityIndicatorVisibleCounter == 1) {
				[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
			}
		} else {
			networkActivityIndicatorVisibleCounter--;
			if(networkActivityIndicatorVisibleCounter < 1) {
				[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
				networkActivityIndicatorVisibleCounter = 0;
			}
		}
	});
}

+ (void)show {
	[self setNetworkActivityIndicatorVisible:YES];
}

+ (void)hide {
	[self setNetworkActivityIndicatorVisible:NO];
}

@end
