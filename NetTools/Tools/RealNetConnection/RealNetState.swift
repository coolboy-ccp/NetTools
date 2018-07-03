//
//  RealNetState.swift
//  NetTools
//
//  Created by 储诚鹏 on 2018/6/29.
//  Copyright © 2018年 储诚鹏. All rights reserved.
//

import UIKit

enum WWANType: Int {
    case unknown = -1
    case _4g
    case _3g
    case _2g
}

enum LocationConnectStatus: Int {
    case unReachable
    case wwan
    case wifi
}

extension LocationConnectStatus {
    static var current: LocationConnectStatus {
        if isReachable() {
            if isWifi() {
                return .wifi
            }
            return .wwan
        }
        return .unReachable
    }
}

enum RRState: Int {
    case invalid = -1
    case unload
    case loading
    case unReachable
    case wifi
    case wwan
}

extension RRState {
    typealias InputInfo = [String : Int]
    
    static let allSates = [invalid, unload, loading, unReachable, wifi, wwan]
    
    func after(input: InputInfo) -> RRState {
        switch self {
        case .invalid:
            return .invalid
        case .unload:
            return try! unloadAfter(input: input)
        default:
            return try! loadAfter(input: input)
        }
    }
}

extension RRState {
    private func getEvent(input: InputInfo) throws -> RREvent {
        guard let eventRaw = input[InfoKeys.eventKey] else {
            throw RealNetError.unknown
        }
        guard let event = RREvent(rawValue: eventRaw) else {
            throw RealNetError.noEvent(eventRaw)
        }
        return event
    }
    
    private func loadAfter(input: InputInfo) throws -> RRState {
        let event = try! getEvent(input: input)
        guard let callback = input[InfoKeys.eventParam] else {
            throw RealNetError.unknown
        }
        switch event {
        case .unload:
            return .unload
        case .ping:
            return try! StateUtil.RRSatate(value: callback)
        case .localConnect:
            return StateUtil.RRSatte(ping: callback > 0)
        default:
            throw RealNetError.errorEvent
        }
    }
    
    private func unloadAfter(input: InputInfo) throws -> RRState {
        let event = try! getEvent(input: input)
        switch event {
        case .load:
            return .loading
        default:
            throw RealNetError.errorEvent
        }
    }
}
