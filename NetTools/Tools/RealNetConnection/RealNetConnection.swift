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
    
    typealias realNetCallback = ((LocationConnectStatus) -> ())
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
    
    private(set) var reachalityStatus: LocationConnectStatus = .unReachable
    
    static let instance = RealNetConnection()
    
    private var notificationComplete: realNetCallback?
    
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
            return
        }
        isNotifying = true
        reachalityStatus = .unReachable
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
    
    func oneMonitoring(_ compelete: realNetCallback? = nil) {
        notificationComplete = compelete ?? notificationComplete
        reachbility()
    }
    
    private func reachbility() {
        let status = LocationConnectStatus.current
        if status == .unReachable || isVPNOn() {
            notificationComplete?(status)
            return
        }
        ping(status: status)
    }
    
    
    private func isVPNOn() -> Bool {
      guard
        let dic = CFBridgingRetain(CFNetworkCopySystemProxySettings()?.takeUnretainedValue())
        else { fatalError(RealNetError.nilSystemProxySettings.localizedDescription) }
      guard
        let scoped = dic["__SCOPED__"] as? [String : Any]
        else { fatalError(RealNetError.nilScoped.localizedDescription) }
      guard
        let en0 = scoped["en0"] as? [String : Any]
        else { fatalError(RealNetError.nilEn0.localizedDescription) }
        let str = en0.reduce("") { (result, dic) -> String in
            return result + "," + dic.key
        }
        let isVPN = (str.range(of: "tap") != nil)  || (str.range(of: "tun") != nil) || (str.range(of: "ipsec") != nil) || (str.range(of: "ppp") != nil)
        if self.isVPN != isVPN {
            self.isVPN = isVPN
            Notification.postNotification(name: .VPNStatusChange)
        }
        return false
    }
    
    @objc private func appBecomeActive() {
        if isNotifying {
            reachbility()
        }
    }
    
    private func autoCheck() {
        if !isNotifying {
            return
        }
        DispatchQueue.doAfter(autoCheckInterval) { [unowned self] in
            self.reachbility()
            self.autoCheck()
        }
    }
    
    @objc private func handleLocalConnection(_ noti: Notification) {
        let lcStatus = LocationConnectStatus.current
        let status = currentReachabilityStatus()
        let input = [InfoKeys.eventKey : RREvent.localConnect.rawValue, InfoKeys.eventParam : lcStatus.rawValue]
        let rtn = engine.receiveInput(input: input)
        if rtn {
            if engine.currentStateIsAvailable() {
                reachalityStatus = status
                notificationComplete?(status)
                if noti.name == .localConnectChange {
                    Notification.postNotification(name: .realNetChange)
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
        pingHelper.ping { [unowned self] (isSuccess)  in
            if isSuccess {
                let input = [InfoKeys.eventKey : RREvent.ping.rawValue, InfoKeys.eventParam : 1]
                let rtn = self.engine.receiveInput(input: input)
                if rtn {
                    if self.engine.currentStateIsAvailable() {
                        self.reachalityStatus = status
                        Notification.postNotification(name: .realNetChange)
                    }
                }
                self.notificationComplete?(status)
            }
            else {
                if !self.isVPNOn() && isFirst {
                    DispatchQueue.doAfter(1.0, doSome: {
                        self.ping(status: status, isFirst: false)
                    })
                }
            }
        }
    }
}
