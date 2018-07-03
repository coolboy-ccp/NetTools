//
//  RealNetError.swift
//  NetTools
//
//  Created by 储诚鹏 on 2018/6/29.
//  Copyright © 2018年 储诚鹏. All rights reserved.
//

import UIKit

enum RealNetError: Error {
    case unknown
    case noEvent(Int)
    case noSate(Int)
    case errorEvent
    case errorConnectState
    case invalidHostName
    case nilSystemProxySettings
    case nilScoped
    case nilEn0
}

extension RealNetError {
    private static let baseDescription = "🌹🌹🌹[RealNetConnection] "
    var localizedDescription: String {
        switch self {
        case .noEvent(let id):
            return RealNetError.baseDescription + "not found a kind of event with id: \(id)"
        case .noSate(let id):
            return RealNetError.baseDescription + "not found a kind of state with id: \(id)"
        case .errorEvent:
            return RealNetError.baseDescription + "use an error event"
        case .errorConnectState:
            return RealNetError.baseDescription + "use an error contection state"
        case .invalidHostName:
            return RealNetError.baseDescription + "use an invalid hostName"
        case .nilSystemProxySettings:
            return RealNetError.baseDescription + "not found CFNetworkCopySystemProxySettings"
        case .nilScoped:
            return RealNetError.baseDescription + "not found scoped in CFNetworkCopySystemProxySettings"
        case .nilEn0:
            return RealNetError.baseDescription + "not found en0 in scoped"
        default:
            return RealNetError.baseDescription + "found unknown error"
        }
    }
}

