//
//  Engine.swift
//  NetTools
//
//  Created by 储诚鹏 on 2018/6/29.
//  Copyright © 2018年 储诚鹏. All rights reserved.
//

import UIKit

class Engine {
    private(set) var currentState: RRState = .invalid
    let allStates = RRState.allSates
    
    func start() {
        currentState = .unload
    }
    
    func currentStateIsAvailable() -> Bool {
        let isAvailable = (currentState == .unReachable) || (currentState == .wwan) || (currentState == .wifi)
        return isAvailable
    }
    
    @discardableResult
    func receiveInput(input: [String : Int]) -> Bool {
        currentState = RRState(rawValue: input[InfoKeys.eventKey] ?? 0) ?? .invalid
        let newState = currentState.after(input: input)
        let result = (newState == currentState) ? false : true
        currentState = newState
        return result
    }
}
