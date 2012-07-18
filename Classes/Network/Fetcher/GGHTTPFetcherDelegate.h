//
//  GGHTTPFetcherDelegate.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 18.07.12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GGHTTPFetcherProtocol.h"

@protocol GGHTTPFetcherDelegate <NSObject>

- (void)fetcher:(NSObject <GGHTTPFetcherProtocol> *)fetcher finishedWithData:(NSData *)data error:(NSError *)error;

@end
