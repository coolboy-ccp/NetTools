//
//  SCNetWork.h
//  NetTools
//
//  Created by 储诚鹏 on 2018/7/2.
//  Copyright © 2018年 储诚鹏. All rights reserved.
//

#ifndef SCNetWork_h
#define SCNetWork_h

#include <stdio.h>
#include <stdbool.h>

typedef void (*handle_block)(void);
void SCNetWork_start(handle_block changed, handle_block initialize);
void SCNetWork_stop(void);
bool isReachable(void);
bool isWWAN(void);
bool isWifi(void);

#endif /* SCNetWork_h */
