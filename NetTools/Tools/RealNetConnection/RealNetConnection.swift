//
//  RealNetConnect.swift
//  NetTools
//
//  Created by 储诚鹏 on 2018/6/29.
//  Copyright © 2018年 储诚鹏. All rights reserved.
//

import UIKit
import CoreTelephony

extension LocationConnectStatus {
    var type: WWANType {
        switch self {
        case .wwan:
            return RealNetConnection.wwanType
        default:
            return .unknown
        }
    }
}

class RealNetConnection {
    
    typealias realNetCallback = (((org: LocationConnectStatus, ping: LocationConnectStatus?)) -> ())
    struct Defaults {
        static let aci: Double = 2.0
        static let timeout: TimeInterval = 2.0
        static let pingHost = "www.apple.com"
        static let checkHost = "www.apple.com"
        static let isVPN = false
        static var finalAci: Double {
            if !(0.3 ... 60.0).contains(aci) {
                return 2.0 * 60
            }
            return aci * 60
        }
    }
    
    private var pingHost: String {
        didSet {
            pingHelper.host = pingHost
        }
    }
    
    private var checkHost: String {
        didSet {
            checkHelper.host = checkHost
        }
    }
    //in seconds
    private var timeout: TimeInterval {
        didSet {
            pingHelper.timeout = timeout
            checkHelper.timeout = timeout
        }
    }
    
    private var isVPN = Defaults.isVPN
    private var isNotifying = false
    private let pingHelper = PingHelper()
    private let checkHelper = PingHelper()
    private let engine = Engine()
    
    private let autoCheckInterval = Defaults.finalAci
    
    private static let _2gStrings = [CTRadioAccessTechnologyEdge,
                              CTRadioAccessTechnologyGPRS,
                              CTRadioAccessTechnologyCDMA1x]
    private static let _3gStrings = [CTRadioAccessTechnologyHSDPA,
                              CTRadioAccessTechnologyWCDMA,
                              CTRadioAccessTechnologyHSUPA,
                              CTRadioAccessTechnologyCDMAEVDORev0,
                              CTRadioAccessTechnologyCDMAEVDORevA,
                              CTRadioAccessTechnologyCDMAEVDORevB,
                              CTRadioAccessTechnologyeHRPD]
    private static let _4gStrings = [CTRadioAccessTechnologyLTE]
    
    static let instance = RealNetConnection()
    
    private var notificationComplete: realNetCallback?
    
    private var previousStatus: LocationConnectStatus = .unReachable
    
    private init() {
        pingHost = Defaults.pingHost
        checkHost = Defaults.checkHost
        timeout = Defaults.timeout
        NotificationCenter.default.addObserver(self, selector: #selector(appBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        engine.start()
    }
    
    fileprivate static var wwanType: WWANType {
        let from = CTTelephonyNetworkInfo().currentRadioAccessTechnology ?? ""
        if _4gStrings.contains(from) {
            return ._4g
        }
        else if _3gStrings.contains(from) {
            return ._3g
        }
        else if _2gStrings.contains(from) {
            return ._2g
        }
        return .unknown
    }
    
    func start(_ compelete: realNetCallback? = nil) {
        if isNotifying {
            stop()
        }
        isNotifying = true
        engine.receiveInput(input: [InfoKeys.eventKey : RREvent.load.rawValue])
        LocalConnection.start()
        NotificationCenter.default.addObserver(self, selector: #selector(handleLocalConnection(_:)), name: .localConnectChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleLocalConnection(_:)), name: .localConnectInitialize, object: nil)
        autoCheck()
        notificationComplete = compelete
    }
    
    func stop() {
        NotificationCenter.default.removeObserver(self)
        engine.receiveInput(input: [InfoKeys.eventKey : RREvent.unload.rawValue])
        LocalConnection.stop()
        isNotifying = false
    }
    
    func onePing(_ compelete: realNetCallback? = nil) {
        let status = currentReachabilityStatus()
        notificationComplete = compelete ?? notificationComplete
        reachbility(status)
    }
    
    private func reachbility(_ status: LocationConnectStatus) {
        if status == .unReachable || isVPNOn() {
            handleBlock(status, nil)
            return
        }
        ping(status: status)
    }
    
    private func handleBlock(_ org: LocationConnectStatus, _ ping: LocationConnectStatus?) {
        if org != previousStatus {
            notificationComplete?((org: org, ping: ping))
            previousStatus = org
        }
    }
    
    
    private func isVPNOn() -> Bool {
      guard
        let dic = CFBridgingRetain(CFNetworkCopySystemProxySettings()?.takeUnretainedValue())
        else { return false }
      guard
        let scoped = dic["__SCOPED__"] as? [String : Any]
        else { return false }
      guard
        let en0 = scoped["en0"] as? [String : Any]
        else { return false }
        let str = en0.reduce("") { (result, dic) -> String in
            return result + "," + dic.key
        }
        let isVPN = (str.range(of: "tap") != nil)  || (str.range(of: "tun") != nil) || (str.range(of: "ipsec") != nil) || (str.range(of: "ppp") != nil)
        if self.isVPN != isVPN {
            self.isVPN = isVPN
        }
        return false
    }
    
    @objc private func appBecomeActive() {
        let status = currentReachabilityStatus()
        if isNotifying {
            reachbility(status)
        }
    }
    
    private func autoCheck() {
        let status = currentReachabilityStatus()
        if !isNotifying {
            return
        }
        DispatchQueue.doAfter(autoCheckInterval) { [unowned self] in
            self.reachbility(status)
            self.autoCheck()
        }
    }
    
    @objc private func handleLocalConnection(_ noti: Notification) {
        let lcStatus = LocationConnectStatus.current
        let input = [InfoKeys.eventKey : RREvent.localConnect.rawValue, InfoKeys.eventParam : lcStatus.rawValue]
        let rtn = engine.receiveInput(input: input)
        let status = currentReachabilityStatus()
        if rtn {
            if engine.currentStateIsAvailable() {
                self.handleBlock(status, nil)
                if lcStatus != .unReachable {
                    reachbility(status)
                }
            }
        }
    }
    
    private func currentReachabilityStatus() -> LocationConnectStatus {
        let currentState = engine.currentState
        switch currentState {
        case .unReachable:
            return .unReachable
        case .wifi:
            return .wifi
        case .wwan:
            return .wwan
        case .loading:
            return LocationConnectStatus.current
        default:
            return .unReachable
        }
    }
    
    private func ping(status: LocationConnectStatus, isFirst: Bool = true) {
        let org = status
        pingHelper.ping { [unowned self] (isSuccess)  in
            if isSuccess {
                let input = [InfoKeys.eventKey : RREvent.ping.rawValue, InfoKeys.eventParam : 1]
                let rtn = self.engine.receiveInput(input: input)
                if rtn {
                    if self.engine.currentStateIsAvailable() {
                        self.handleBlock(org, status)
                        return
                    }
                }
            }
            else {
                if !self.isVPNOn() && isFirst {
                    DispatchQueue.doAfter(1.0, doSome: {
                        self.ping(status: org, isFirst: false)
                    })
                }
            }
        }
    }
}
