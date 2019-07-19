//
//  ViewController.swift
//  SwiftyState
//
//  Created by mrtksn on 07/07/2019.
//  Copyright (c) 2019 mrtksn. All rights reserved.
//


import UIKit
import SwiftyState

class ViewController: UIViewController {
    @IBOutlet weak var maxSwitchCountLabel: UILabel!
    @IBOutlet weak var maxStepper: UIStepper!
    
    var sub : SwiftySubscription?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Enable SwiftyState Debuggur UI to be displayed when you shake your device. Remove this one before shipping unless you want to expose the debugger to your users
        SwiftyState().debugUIManager().showOnShake(self)
 
        /* Start a subscription to state changes */
        self.sub = SwiftyState().subscribe(f: { [weak self] in
            let state = $0 as! MyStore //get the new state
            if let oldState = $1 as? MyStore {
                oldState.maxSwitches.hasChanged()
        //get the old state and check for changes against the new state
                if state.switchesTurnedOn.count != oldState.switchesTurnedOn.count {
                    //Update if the count of switches is different from the previous state
                    self?.updateCounter()
                }
                if state.maxSwitches != oldState.maxSwitches {
                    //Update if the maxSwitches value is different from the previous state
                    self?.updateCounter()
                    self?.maxStepper.value = Double(state.maxSwitches)
                }
                
                
                
            }else{
        //if cannot get the old state(i.e. there is no old state because this is the initial state), do the following
                self?.updateCounter()
                self?.maxStepper.value = Double(state.maxSwitches)
            }
            
        
        })
        /// This will call the code block in the subscription at the start. Us it to initialize the default state. Since there is no old state, the old state will be nil
        self.sub?.hotStart()
    }
    
    func updateCounter(){
        //get the most recent state
        let state = SwiftyState().getState()
        // get the number of switches that are turned on at the moment
        let switchedOnNum = state.switchesTurnedOn.count
        let max = state.maxSwitches
        self.maxSwitchCountLabel.text = "\(switchedOnNum) of \(max)"
        
    }


    @objc func turnOff(_ id: String){
        
    }
    
    @IBAction func flipSwitch(_ sender: AutoSwitch) {
        guard let id = sender.id else {
            return
        }
        if sender.isOn{
            SwiftyState().action(a: SnakeActions.turnSwitchOn(id: id))
        }else{
            SwiftyState().action(a: SnakeActions.turnSwitchOff(id: id))
        }
    }
    @IBAction func changeMaxCount(_ sender: UIStepper) {
        SwiftyState().action(a: ControlActions.setMaxTo(max: Int(sender.value)))
    }
    
    @IBAction func ban(_ sender: Any) {
        SwiftyState().action(a: ControlActions.banSwitches)
    }
    @IBAction func liftBan(_ sender: Any) {
        SwiftyState().action(a: ControlActions.liftBan)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

