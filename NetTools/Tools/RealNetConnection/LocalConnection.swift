//
//  LocalConnection.swift
//  NetTools
//
//  Created by 储诚鹏 on 2018/6/29.
//  Copyright © 2018年 储诚鹏. All rights reserved.
//

import UIKit

class LocalConnection {
    
    static func start() {
        let connectChanged: @convention(c) () -> () = {
            Notification.postNotification(name: .localConnectChange)
        }
        
        let connectInitializer: @convention(c) () -> () = {
            Notification.postNotification(name: .localConnectInitialize)
        }
        
        SCNetWork_start(connectChanged, connectInitializer)
    }
    
    static func stop() {
        SCNetWork_stop()
    }
    
}
