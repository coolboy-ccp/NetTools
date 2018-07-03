//
//  SCNetWork.c
//  NetTools
//
//  Created by 储诚鹏 on 2018/7/2.
//  Copyright © 2018年 储诚鹏. All rights reserved.
//

#include "RNCc.h"
#include <SystemConfiguration/SystemConfiguration.h>
#include <arpa/inet.h>

static SCNetworkReachabilityRef reachabilityRef;
static dispatch_queue_t reachabilityQueue;
static handle_block post_notification_changed;
static handle_block post_notification_initialize;

static SCNetworkReachabilityRef reachbilityRef() {
    struct sockaddr_in address;
    bzero(&address, sizeof(address));
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;
    return SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *) &address);
}

static bool isConditionTrue(bool (*condition)(SCNetworkReachabilityFlags)) {
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
        return condition(flags);
    }
    return false;
}

static bool reachable(SCNetworkReachabilityFlags flags) {
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
        return false;
    }
    
    if ((flags & kSCNetworkFlagsConnectionRequired) == 0) {
        return true;
    }
    
    if ((flags & (kSCNetworkReachabilityFlagsConnectionOnDemand | kSCNetworkReachabilityFlagsConnectionOnTraffic)) != 0) {
        return (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0;
    }
    return false;
}

static bool wwan(SCNetworkReachabilityFlags flags) {
    if (flags & kSCNetworkReachabilityFlagsReachable) {
        return (flags & kSCNetworkReachabilityFlagsIsWWAN);
    }
    return false;
}

static bool wifi(SCNetworkReachabilityFlags flags) {
    if((flags & kSCNetworkReachabilityFlagsReachable)) {
         return !(flags & kSCNetworkReachabilityFlagsIsWWAN);
    }
    return false;
}

bool isReachable() {
    return isConditionTrue(reachable);
}

static void post_notifocation(void (*postFunc)(void)) {
    isReachable();
    if (postFunc != NULL) {
        postFunc();
    }
}

static void localConnectCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    post_notifocation(post_notification_changed);
}

static void setSCNetContext() {
    SCNetworkReachabilityContext context = { 0, NULL, NULL, NULL, NULL };
    Boolean isSuccess = SCNetworkReachabilitySetCallback(reachabilityRef, localConnectCallback, &context);
    if (isSuccess) {
        Boolean isFailed = !SCNetworkReachabilitySetDispatchQueue(reachabilityRef, reachabilityQueue);
        if (isFailed) {
            SCNetworkReachabilitySetCallback(reachabilityRef, NULL, NULL);
            printf(" 🌹🌹🌹 SCNetworkReachabilitySetCallback() failed. Error: %s", SCErrorString(SCError()));
        }
    }
    else {
        printf(" 🌹🌹🌹 SCNetworkReachabilitySetCallback() failed. Error: %s", SCErrorString(SCError()));
    }
    post_notifocation(post_notification_initialize);
}

static void nullValue(void *value) {
    if (value != NULL) {
        CFRelease(value);
        value = NULL;
    }
}

void SCNetWork_start(handle_block changed, handle_block initialize) {
    reachabilityQueue = dispatch_queue_create("com.nettools.realreachability", NULL);
    reachabilityRef = reachbilityRef();
    post_notification_changed = changed;
    post_notification_initialize = initialize;
    setSCNetContext();
}

void SCNetWork_stop() {
    SCNetworkReachabilitySetCallback(reachabilityRef, NULL, NULL);
    SCNetworkReachabilitySetDispatchQueue(reachabilityRef, NULL);
    nullValue((void *)reachabilityRef);
    nullValue(post_notification_changed);
    nullValue(post_notification_initialize);
    reachabilityQueue = nil;
}

bool isWWAN() {
   return isConditionTrue(wwan);
}

bool isWifi() {
    return isConditionTrue(wifi);
}





