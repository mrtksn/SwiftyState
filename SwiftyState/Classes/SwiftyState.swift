//
//  StateMachine.swift
//  stopsmoking
//
//  Created by Mertol Kasanan on 30/01/2019.
//  Copyright © 2019 Mertol Kasanan. All rights reserved.
//
import Foundation

/// SwiftyState gives you an instace of the state machine. You can call actions by State SwiftyState().action() or you can subscribe to updates by calling SwiftState().subscribe()
public class SwiftyState {
    /// The name of the state file on the disk. Used to persist the state between sessions.
    private let stateFileName = "SwiftyState.json"
    /// The instance of the state
    private var machineState : SwiftyStateMachineState
    
    public init() {
        /* Make sure that all instances work with the same data */
        self.machineState = SwiftyStateMachineState.instance
        
    }
    
    public func setStore<T: SwiftyStateStore>(_ store: T){
        self.machineState.state = store
    }
    
    /// Returns a copy of the state
    ///
    /// - Returns: the state object
    public func getRawState()->SwiftyStateStore{
        let state = self.machineState.state
        return state! // .copy() consumes a lot of resources
    }
    
    
    
    /// Use this to call the actions you created
    ///
    /// - Parameters:
    ///   - a: the StateAction that should be called
    ///   - force: should be force notified
    public func action<T : SwiftyAction>(a : T, force: Bool = false){
        let result = a.execute(self.getRawState())
        
        let resultIsValid = self.validateState(result.state)
        
        /// If debugging is on
        if self.machineState.debug {
            self.addToHistory(action: a, state: result.state, valid: resultIsValid)
        }
        
        /// If the engine is on
        if self.machineState.engineOn {
            /// Validate the state and return the new state if
            self.machineState.state = resultIsValid ? result.state : result.oldState
            self.notify(state: self.machineState.state!, oldState: result.oldState, force: force)
        }
    }
    
    /// Validate the provided state against the defined stated validator
    ///
    /// - Parameter state: the state that will be validated
    /// - Returns: true if the state is valid, false if the state is not valid. If no state validator is defined it will return true.
    public func validateState(_ state : SwiftyStateStore)->Bool{
        guard let stateValidiator = self.machineState.stateValidiator else {
            return true
        }
        return stateValidiator.validiator(state)
    }
    
    /// Get the state history
    ///
    /// - Returns: Returns an array of the states with metadata
    func getHistory()->[SwiftyStateStoreHistory]{
        return self.machineState.stateHistory
    }
    /// Add a history point
    ///
    /// - Parameters:
    ///   - action: an action
    ///   - state: the resulting state
    ///   - valid: was the state accepted as valid and applied or not
    func addToHistory<T : SwiftyAction>(action: T, state: SwiftyStateStore, valid : Bool = true){
        let actionDesciption = String(describing: action)
        let historyPoint = SwiftyStateStoreHistory(action: actionDesciption, state: state, valid: valid)
        self.machineState.stateHistory.append(historyPoint)
    }
    /// Start collecting debug information like history
    public func startDebug(){
        if self.machineState.stateHistory.count == 0 {
            let historyPoint = SwiftyStateStoreHistory(action: "SwiftyState debug started", state: self.getRawState())
            self.machineState.stateHistory.append(historyPoint)
        }
        self.machineState.debug = true
    }
    /// Stop collecting debug
    public func stopDebug(){
        self.machineState.debug = false
    }
    /// Start notifying state updates
    public func startEngine(){
        self.machineState.engineOn = true
    }
    /// Stop notifying state updates
    public func stopEngine(){
        self.machineState.engineOn = false
    }
    
    /// Get the Debug UI Manager
    ///
    /// - Returns: Debug UI
    public func debugUIManager()->SwiftyStateDebugUIManager{
        return SwiftyStateDebugUIManager()
    }
    
    /// Get the DebugUI ViewController
    ///
    /// - Returns: DebugUI ViewController
    func getDebugUI()->SwiftyStateDebuggerViewController?{
        return self.machineState.debugUI
    }
    
    /// Set the DebugUI ViewController
    ///
    /// - Parameter debugViewController: SwiftyStateDebuggerViewController instance
    func setDebugUI(_ debugViewController: SwiftyStateDebuggerViewController){
        self.machineState.debugUI = debugViewController
    }
    
    /// returns engine config
    func getConfig()->(engineOn: Bool, debug: Bool){
        return (engineOn: self.machineState.engineOn, debug: self.machineState.debug)
    }
    
    /*
     idea: maybe we can add  @discardableResult to stop xCode warnings? But maybe theyare useful...
     */
    /// Subscribe to receive updates when the state changed
    ///
    /// - Parameter f: This is a closure that you should provide. The closure will be executed when the state changes. You should take care of the logic.
    /// - Returns: Subscription ID. Use this ID to unsubscribe when you no longer need to listen to updates or want to free up resources.
    public func subscribe(f : @escaping (_ state: SwiftyStateStore, _ oldState: SwiftyStateStore?)->Void)->SwiftySubscription{
        self.machineState.counter += 1
        let id = "f\(self.machineState.counter)"
        
        self.machineState.subscribers[id] = f
        
        return SwiftySubscription(id: id)
    }
    /* pass the subscription id to unsubcsribe */
    /// Unsubscribe from listeing to state changes
    ///
    /// - Parameter id: Subscription id
    public func unsubscribe(_ id : String){
        self.machineState.subscribers.removeValue(forKey: id)
    }
    
    /* Call the subscribers*/
    /// This will notify the subscribers
    ///
    /// - Parameters:
    ///   - state: the new state
    ///   - oldState: the old state
    ///   - force: should be forced or not
    private func notify(state: SwiftyStateStore, oldState: SwiftyStateStore, force : Bool = false){
        for (_, f) in self.machineState.subscribers {
            f(state, oldState)
        }
    }
    
    /// Force subscription execution
    ///
    /// - Parameter id: Subscription ID
    func executeSubscription(id : String){
        let f = self.machineState.subscribers[id]
        let state = getRawState()
        f?(state, nil)
    }
    
    /// Define a state validiator
    ///
    /// - Parameter validiator: an object that has a closure that receives the new state for validation. Returns true to accept and false to reject the state.
    public func setStateValidiator(_ validiator : SwiftyStateValidiator){
        self.machineState.stateValidiator = validiator
    }
    
    
    
    
    /* THE FILE MANAGEMENT FUNCTIONS
     * You can create a persistent state
     * by loading the state at the application start and saving the state after changes are made.
     * Use the load() and save() methods to manage the state persistence
     * It is recommended to use the application lifecycle functions to save the state however you
     * can save the state anytime you want.
     */
    
    /// returns the file path of the file on the disk
    ///
    /// - Returns: File path as a String
    func getFilePath()->String{
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
        let fullPath = url!.appendingPathComponent(self.stateFileName).path
        return (fullPath)
    }
    
    /// Save the state to disk
    public func save(){
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let json = self.getRawState().toData()
        let manager = FileManager.default
        if !manager.fileExists(atPath: getFilePath()) {
            manager.createFile(atPath: getFilePath(), contents: json)
        }else{
            do{
                try json.write(to: URL(fileURLWithPath: getFilePath()))
                
            }catch{
                print("can't write SwiftyState file")
            }
            
        }
        
    }
    /// Load the state from disk
    public func load(){
        let manager = FileManager.default
        let filePath = getFilePath()
 
            if manager.fileExists(atPath: filePath) {
                guard let json = String.init(data: manager.contents(atPath: filePath)!, encoding: String.Encoding.utf8) else {
                    print("SwiftState was not able to convert the state file, proceeding with the default state")
                    return
                }
                guard let state = self.machineState.state?.fromJSON(json) else {
                    print("SwiftState was not able to convert the JSON, proceeding with the default state")
                    return
                }
                self.machineState.state = state
                self.notify(state: self.machineState.state!, oldState: self.machineState.state!, force: true)
            }else{
                print("SwiftyStae file does not exist. Proceeding with the default state")
        }
    }
    
    /// Load the state from the provided JSON String
    ///
    /// - Parameter json: String containing JSON
    public func loadJSON(_ json : String){
        guard let state = self.machineState.state?.fromJSON(json) else {
            print("SwiftState was not able to convert the JSON")
            return
        }
        self.machineState.state = state
    }
    
    /// Remove the saved state from the disk. Call this before loading the state.
    public func resetSavedState(){
        self.deleteFile()
    }
    
    /// delete the file on the disk
    func deleteFile(){
        let manager = FileManager.default
        do{
            try manager.removeItem(at: URL(fileURLWithPath: getFilePath()))
            print("SwiftState file deleted")
        }catch{
            print("Can't delete SwiftyState file")
        }
    }
    
    
}

/// The SwiftyStateMachineState is a singleton that preserves the state machine state across instances
public class SwiftyStateMachineState {
    /// the singleton instance
    static var instance = SwiftyStateMachineState()
    /// List of the subscribers that will be notified if the state changes
    var subscribers : [String : (SwiftyStateStore, SwiftyStateStore?)->Void] = [String : (SwiftyStateStore, SwiftyStateStore?)->Void]()
    /// counter used to create unique ID's
    var counter : Int = 0
    /// The state
    var state : SwiftyStateStore?
    /// Should SwiftyState collect state change history data?
    var debug = false
    /// Debugger UI
    weak var debugUI : SwiftyStateDebuggerViewController?
    /// Should SwiftyState respond to actions?
    var engineOn = true
    /// The state validiator
    var stateValidiator : SwiftyStateValidiator?
    /// State change history
    var stateHistory : [SwiftyStateStoreHistory] = [SwiftyStateStoreHistory]()
    /// private init, to make sure that only one instance is created
    private init(){
        
    }
}
