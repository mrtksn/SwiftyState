//
//  SwiftyStateSupplements.swift
//  Pods
//
//  Created by Mertol Kasanan on 08/07/2019.
//

import Foundation

/// Conform to this to have equatable store
public protocol SwiftyStateStoreEquatable : SwiftyStateStore, Equatable{
    func hasChanged(_ property : String)->Bool
}

public extension SwiftyStateStoreEquatable {
    public func hasChanged(_ property : String)->Bool{
        return false
    }
}

/// The object that holds the state, not equatable
public protocol SwiftyStateStore :  Codable {
    /// A JSON String representation of the state
    ///
    /// - Returns: JSON as a String
    func toJSON()->String
    /// a Data representation of the state
    ///
    /// - Returns: Data
    func toData()->Data
    /// Converts a JSON String to an object
    ///
    /// - Parameter json: JSON String
    /// - Returns: Returns an object representing the state
    func fromJSON(_ json: String)->SwiftyStateStore?
}

// MARK: - The object that contains the state data. Inherit from this
public extension SwiftyStateStore{
    
    func toData()->Data{
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        
        let jsonObject = try! encoder.encode(self)
        
        return jsonObject
    }
    
    
    func toJSON()->String{
        let json = NSString(data: self.toData(), encoding: String.Encoding.utf8.rawValue)
        return String(json ?? "error")
    }
    
    
    func fromJSON(_ json: String)->SwiftyStateStore?{
        let decoder = JSONDecoder()
        var stateObject : Self?
        do{
            stateObject = try decoder.decode(Self.self, from: json.data(using: .utf8)!)
            
        }catch{
            print("Can't load SwiftState file \(error)")
        }
        return stateObject
    }
    
}

/// State Validiator. Create a function that returns true if the state is valid, false if there is a problem and the state is not valid.
public protocol SwiftyStateValidiator {
    func validiator(_ state : SwiftyStateStore)->Bool
}

/// State and meta data. Used as a history point
public struct SwiftyStateStoreHistory {
    let date : Date
    let action: String
    let state : SwiftyStateStore
    let valid: Bool
    init(action: String, state: SwiftyStateStore, valid: Bool = true) {
        self.date = Date()
        self.action = action
        self.state = state
        self.valid = valid
    }
}





/// It is returned by the subscribe function
public class SwiftySubscription {
    public let id : String
    init(id : String) {
        self.id = id
    }
    
    /// unsubscribe
    public func unsubscribe(){
        SwiftyState().unsubscribe(self.id)
    }
    
    /// call once at the start
    public func hotStart(){
        SwiftyState().executeSubscription(id: self.id)
    }
    
}

/// You can extend this and add SwiftyActions to make it auto-complete friendly
public struct AvailableSwiftyActions{
    
}

public protocol SwiftyActionDefaultProtocol : SwiftyAction {
    
}

extension SwiftyActionDefaultProtocol {
    public static var available : AvailableSwiftyActions.Type {return AvailableSwiftyActions.self }
}

/// An empty action that can be used to access AvailableSwiftyActions via .available
public enum SwiftyActionDefault : SwiftyActionDefaultProtocol {
    public func reducer(state: SwiftyStateStore) -> SwiftyStateStore {
        return state
    }
}

/// State Actions are actions that modify the state when called
public protocol SwiftyAction {
    // associatedtype action
    func execute(_ currState : SwiftyStateStore)->(state: SwiftyStateStore, oldState: SwiftyStateStore)
    func reducer(state : SwiftyStateStore)->SwiftyStateStore
}

// MARK: - the execute function reduces boilerplate code by taking the arguments and calling the reducer. The user must create a reducer
extension SwiftyAction {
    /// Runs the reducer to modify the state
    ///
    /// - Parameter currState: The current state
    /// - Returns: the modified state
    public func execute(_ currState : SwiftyStateStore)->(state: SwiftyStateStore, oldState: SwiftyStateStore){
        let state = self.reducer(state: currState)
        return (state: state, oldState : currState)
    }
}
