//
//  StateUtil.swift
//  NetTools
//
//  Created by 储诚鹏 on 2018/6/29.
//  Copyright © 2018年 储诚鹏. All rights reserved.
//

import UIKit

extension DispatchQueue {
    static func doAfter(_ time: TimeInterval, doSome: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + time) {
            doSome()
        }
    }
}

extension Notification {
    static func postNotification(name: Notification.Name) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: nil)
        }
    }
}

extension Notification.Name {
    static let localConnectChange = Notification.Name("localConnectChangeNotification")
    static let localConnectInitialize = Notification.Name("localConnectInitializeNotification")
}

struct InfoKeys: Hashable {
    private static let baseKey = "RealNetConnect_"
    static let eventKey = baseKey + "eventKey"
    static let eventParam = baseKey + "eventParameter"
}

enum RREvent: Int {
    case load
    case unload
    case localConnect
    case ping
}

enum ConnectType: Int {
    case unreachable
    case wifi
    case wwan
}

class StateUtil {
    static func RRSatate(value: Int) throws -> RRState {
        guard let type = ConnectType(rawValue: value) else {
            throw RealNetError.noEvent(value)
        }
        switch type {
        case .unreachable:
            return .unReachable
        case .wifi:
            return .wifi
        case .wwan:
            return .wwan
        }
    }
    
    static func RRSatte(ping: Bool) -> RRState {
        let state = LocationConnectStatus.current
        if !ping {
            return .unload
        }
        switch state {
        case .unReachable:
            return .unReachable
        case .wifi:
            return .wifi
        case .wwan:
            return .wwan
        }
    }
}
