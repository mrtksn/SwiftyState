//
//  AutoSwitch.swift
//  SwiftyState_Example
//
//  Created by Mertol Kasanan on 09/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import SwiftyState

class AutoSwitch: UISwitch {
    var subscription : SwiftySubscription?
    var id : String?
    var banned : Bool = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.prep()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.prep()
    }
    
    /// shared init function
    func prep(){
        self.id = UniqueIDGenerator().string() // generate an unique ID, it will be used to identify the switch
        self.isOn = true // the starting state of the switch is ON
        
        /// Start watcing the state changes
        self.subscription = SwiftyState().subscribe { [weak self] in
            /// Notice that the self is weak. This is because we don't want to create a strong reference to itself since this will result in memory leak if we remove the object later
            let state = $0 as! MyStore // $0 is the new state
            _ = $1 as? MyStore // $0 is the old state. In this case we did not need the old state but we still had to account for it
            
            guard let id = self?.id else {
                return
            }

            /// We are checking if this switch is in the "Turn on" list and reflect it accordingly. Every time an action is fired this will be executed
            if state.switchesTurnedOn.contains(id){
                self?.setOn(true, animated: true)
            }else {
                if self!.isOn {
                    self?.turnOffWithDelay()
                }
            }
            
            /// We are checking if the switch is in the "banned" list and reflect the result to the UI
            if state.bannedSwitches.contains(id){
                self?.setBanState(true)
            }else{
                self?.setBanState(false)
            }
            
        }
        /// This will call the code block in the subscription at the start. Us it to initialize the default state. Since there is no old state, the old state will be nil
        self.subscription?.hotStart()
    }
    
    /// turn off the switch
    @objc func turnOff(){
        self.setOn(false, animated: true)
    }
    
    /// turn off the switch but with a delay
    func turnOffWithDelay(){
        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(turnOff), userInfo: nil, repeats: false)
    }
    
    func setBanState(_ banned : Bool){
        if self.banned == banned {
            return
        }
        self.banned = banned
        let alpha : CGFloat = banned ? 0.3 : 1.0
        
        UIView.animate(withDuration: 0.2) {[weak self] in
            self?.alpha = alpha
        }
    }
}



/// Simply an unique ID generator, used to save us from manually defining unique object Ids. It's unrelated to SwiftyState, used for the demo
class UniqueIDGenerator {
    var instance = UniqueIDGeneratorData.string
    init() {
        
    }
    
    func string() -> String {
        self.instance.id += 1
        return "s\(self.instance.id)"
    }
}
/// Singleton where we keep the UniqueIDGenerator's progress
class UniqueIDGeneratorData {
    static let string = UniqueIDGeneratorData()
    var id : Int = 0
    
    private init(){}
    
}
