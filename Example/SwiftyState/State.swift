//
//  State.swift
//  SwiftyState_Example
//
//  Created by Mertol Kasanan on 08/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import SwiftyState


/// This is your store
struct MyStore : SwiftyStateStoreProtocol {
    var switchesTurnedOn : [String] = [String]()
    var maxSwitches : Int = 1
    var bannedSwitches : [String] = [String]()
}

 

// MARK: - Extend SwiftyState to reduce boilerplate
extension SwiftyState {
    func getState()->MyStore{
        return self.getRawState() as! MyStore
    }
}

/// Create a validator that will acceot or reject the state.
struct MyValidator : SwiftyStateValidiator{
    func validiator(_ state: SwiftyStateStoreProtocol) -> Bool {
        let newState = state as! MyStore
        
        // Reject the state if max switches is negative
        if newState.maxSwitches < 0 {
            return false
        }
        // Reject the state if the new state contains banned switches
        for id in newState.switchesTurnedOn {
            if newState.bannedSwitches.contains(id){
                return false
            }
        }
        
        return true
    }
}

/// Actions that control the switches
///
/// - turnSwitchOn: turns on a switch
/// - turnSwitchOff: turns off a switch
enum SnakeActions : SwiftyAction{
    
    case turnSwitchOn(id: String)
    case turnSwitchOff(id: String)
    func reducer(state: SwiftyStateStoreProtocol) -> SwiftyStateStoreProtocol {
        var newState = state as! MyStore
        
        switch self {
        case .turnSwitchOn(let id):
            newState.switchesTurnedOn.append(id)
            let numSwitchesOn = newState.switchesTurnedOn.count
            let max = newState.maxSwitches
            
            if numSwitchesOn > max {
                    newState.switchesTurnedOn.removeFirst(numSwitchesOn - max)
            }
            
        case .turnSwitchOff(let id):
            newState.switchesTurnedOn.removeAll { (currId) -> Bool in
                return currId == id
            }
        }
        return newState
    }
}

/// Actions to controll the settings
///
/// - setMaxTo: set the maximum number of switches that can be turned on at a time
/// - banSwitches: ban the currently "on" switches
/// - liftBan: remove the switch ban
enum ControlActions : SwiftyAction {
    
    case setMaxTo(max : Int)
    case banSwitches
    case liftBan
    
    func reducer(state: SwiftyStateStoreProtocol) -> SwiftyStateStoreProtocol {
        var newState = state as! MyStore
        
        switch self {
        case .setMaxTo(let max):
            newState.maxSwitches = max
        case .banSwitches:
 
            for id in newState.switchesTurnedOn{
                if !newState.bannedSwitches.contains(id) {
                    newState.bannedSwitches.append(id)
               
                }
            }
            newState.switchesTurnedOn.removeAll()
        case .liftBan:
            newState.bannedSwitches.removeAll()
        }
        
        return newState
    }
    
    
}
