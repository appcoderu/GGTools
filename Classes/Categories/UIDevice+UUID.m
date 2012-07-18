//
//  UIDevice+UUID.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 05.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "UIDevice+UUID.h"
#import "NSString+Crypto.h"

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

static NSString *macAddressString = nil;
static NSString *UUID = nil;

@implementation UIDevice (UUID)

- (NSString *)macAddress {
	if (nil != macAddressString) {
		return macAddressString;
	}
	
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    size_t              length;
	
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;              
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)  {
		return nil;
	}
	
    // Get the size of the data available (store in len)
    if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)  {
		return nil;
	}
	
    // Alloc memory based on above call
    if ((msgBuffer = malloc(length)) == NULL) {
		return nil;
	}
	
    // Get system information, store in buffer
    if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0) {
        free(msgBuffer);
        return nil;
    }
	
	// Map msgbuffer to interface message structure
	struct if_msghdr *interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
	
	// Map to link-level socket structure
	struct sockaddr_dl *socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
	
	// Copy link layer address data in socket structure to an array
	unsigned char macAddress[6];
	memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
	
	macAddressString = [[NSString alloc] initWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
						macAddress[0], macAddress[1], macAddress[2], macAddress[3], macAddress[4], macAddress[5]];        
	// Release the buffer memory
	free(msgBuffer);
	
	return macAddressString;
}

- (NSString *)UUID {
	if (nil != UUID) {
		return UUID;
	}
	
	NSString *mac = [self macAddress];
	if (!mac) {
		return [@"" sha1];
	}
	
	UUID = [[NSString stringWithFormat:@"%@%@", mac, [self model]] sha1];
	
	return UUID;
}

@end
