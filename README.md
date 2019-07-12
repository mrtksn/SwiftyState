# SwiftyState

### v1.0

SwiftyState is a **State Engine** featuring a powerful **on-device debugger with a graphical user interface**. You can also do time travel in your app. Inspired by the Redux JS Library but not too much.

*Here is a video preview of the Demo App. The UIKit elements automatically update as the state changes. The interface at the bottom is the on-device debugger where the developer can view and undo state changes.*
[![SwiftyState Demo App](http://img.youtube.com/vi/TwmqQTe3K58/0.jpg)](http://www.youtube.com/watch?v=TwmqQTe3K58)

### What is it for?

In SwiftState  you create a *central source of truth*, a *state*, which is a fancy way to say a *struct* that keeps your app data. You can modify that data only by calling actions and you subscribe to get notified when someting has changed.

This enables you to create independent components that simply observe the state and act accordingly without worrying about the other parts of the App.  Having all your data in one place simplifies verifying it's validity and management.  

For example, how do you persist your App state between sessions? With SwiftyState you don't have to do almost anything, you simply call save() or load() to save and load the state from the disk and it's done. Don't want to to keep your data on disk want it online? Easy, SwiftState exports and imports JSON  so you have the state of your app anywhere.

Having a graphical debugger that runs on iOS will also help you to hunt bugs, understand quirks or admire the internals of your creation even when you do not have XCode with you. Simply shake your device and the debugger will pop up(If you choose to).

### The on-device state debugger

SwiftyState comes with a debugger that runs on iOS and can be launced by shaking the device(this can be changed). It is an standalone UI where you can view the current state, the actions and you can roll back to a previous state - time travel.

## Example

First thing first, you need to import SwiftyState

```Swift
import SwiftyState
```

#### Create your state object

In SwiftyState, you need to define your state structure. You have only one of these.

```Swift
/// This is your store. It is a struct that conforms to the SwiftyStateStoreProtocol
struct MyStore : SwiftyStateStoreProtocol {
    var Jenny : Int = 100
    var Donald : Int = 20
}
/// Add this to make SwiftState return your store when asked
extension SwiftyState {
    func getState()->MyStore{
        return self.getRawState() as! MyStore
    }
}
```

So by default Jenny has 100 dollars and Donald only 20. These values are available anywhere in your app. You can access them getting the latest copy of your state

```Swift
/// Get a copy of your state
let state = SwiftyState().getState()

print("Jenny owns \(state.Jenny) and Donald owns \(state.Donald)")
/// the output is "Jenny owns 100 and Donald owns 20"
```

#### Create actions

How do you change state? You create actions and call these actions to correctly modify your data.

Here is an action to make Jenny give Donald 10 bucks. You simply conform to SwiftyAction protocol with an enum, add your actions as cases and write the logic of the action inside the reducer function.

Don't worry, it's autocomplete friendly. XCode(or your favorite IDE) will help you out so you don't have to write too much code.

```Swift
enum PayAction : SwiftyAction {
    case give10BuckToDonald

    func reducer(state: SwiftyStateStoreProtocol) -> SwiftyStateStoreProtocol {
        var newState = state as! MyStore
        switch self {
        case .give10BuckToDonald:
            newState.Donald += 10
            newState.Jenny -= 10
        }
        // When you are done changing, always return the new state
        return newState
    }
}
```

Anywhere in your app you can call this action and Jenny will give Donald 10 dollars. You call actions like this:

```Swift
SwiftyState().action(a: PayAction.give10BuckToDonald)
```

Okay, how about giving custom amount? Let's add another action

```Swift
enum PayAction : SwiftyAction {
    case give10BuckToDonald
    case giveToDonald(amount : Int)

    func reducer(state: SwiftyStateStoreProtocol) -> SwiftyStateStoreProtocol {
        var newState = state as! MyStore
        switch self {
        case .give10BuckToDonald:
            newState.Donald += 10
            newState.Jenny -= 10
        case .giveToDonald(let amount):
            newState.Donald += amount
            newState.Jenny -= amount
        }
        // When you are done changing, always return the new state
        return newState
    }
}
```

Then call that action from anywhere

```Swift
SwiftyState().action(a: PayAction.giveToDonald(amount: 5))
```

Do you see the pattern here? You can keep adding actions as you need and it doesn't have to be in one place.  For example, let's create a StealAction that will steal from Donald and Jenny

```Swift
enum StealAction : SwiftyAction{
    case stealAll

    func reducer(state: SwiftyStateStoreProtocol) -> SwiftyStateStoreProtocol {
        var newState = state as! MyStore
        newState.Donald = 0
        newState.Jenny = 0
        return newState
    }
}
```

Call from anywhere

```Swift
SwiftyState().action(a: StealAction.stealAll)
```

#### Listen to changes

Good way to have independent components is to make them aware of your data and adapt as the data changes. You do that by subscribing to state changes, like this:

```Swift
let subscription = SwiftyState().subscribe { [weak self] in
    let state = $0 as! MyStore
    let oldState = $1 as? MyStore

    /// Your code goes here
}
```

The `SwiftyState().subscribe()` method return a  `SwiftySubscription` object that holds an ID and an unsubscribe method. If your object is no longer needed, do not forget to unsubscribe to prevent memory leaks.

For example, when you are using SwiftState with UIKit, the best place to subscribe to changes is in the viewDidLoad() for a ViewController and unsubscribe in the deinit(). Let's have a look:

```Swift
class MoneyStatus : UIViewController {
    var subscription : SwiftySubscription?

    override func viewDidLoad() {
        self.subscription = SwiftyState().subscribe { [weak self] in
            let state = $0 as! MyStore // the new state
            let oldState = $1 as? MyStore // the old state
            // if the state changed, apply the changes
            if state.Donald != oldState?.Donald{
                print("Donald now owns \(state.Donald)$")
            }
        }
        // execute the closure at the start
        self.subscription?.hotStart()
    }

    // free up resources when you no longer need it
    deinit {
        self.subscription?.unsubscribe()
    }
}
```

#### Validate changes

With SwiftyState you have the option to reject action results if you are not happy with the results. For example, let's make sure that Jenny and Donald do not acquire debt.

```Swift
struct MyValidator : SwiftyStateValidiator{
    func validiator(_ state: SwiftyStateStoreProtocol) -> Bool {
        // the new state is available here, before making it available everywhere:
        let newState = state as! MyStore

        return (newState.Donald >= 0) && (newState.Jenny >= 0)
    }
}
```

It's quite simple really. You create a struct that conforms to `SwiftyStateValidiator` which means that you will have a validiator function that receives the new state every time an action is run. You evaluate the new state and return `true` if it is O.K. or return `false` if not. If you return `false`, the new state is discarded and the old state is passed.

#### Keep In Mind

SwiftyState runs synchronously on the main thread. This means that if you do heavy calculations inside the actions or subscriptions the app may freeze until your code ise done. Keep the actions pure(that is, only modify the state using the data available for the reducer, no async inside the actions) and if you have heavy calculations, use SwiftState subscriptions to initiate them asynchronously or in seperate treads.

An exaple app is included, please take a look.

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

#### get SwiftState

SwiftyState is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SwiftyState'
```

#### Integrate into your project

As with any framework, import SwiftState wherever you use SwiftyState

```Swift
import SwiftyState
```

Create your State and Validiator objects as described. Keeping them in a seperate Swift file is usually good idea.

Initiate the SwiftyState in the `didFinishLaunchingWithOptions` method, in your `AppDelegate.swift`. It is recommended to save and load the state from disk to keep your data between sessions.

```Swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    //Configure SwiftyState to use your State object
    SwiftyState().setStore(MyStore())
    // Configure SwiftState to use your validator
    SwiftyState().setStateValidiator(MyValidator())
    // Load the state from the disk
    SwiftyState().load()
    // Start collecting state history for debugging. Remove this one before shipping
    SwiftyState().startDebug()
    return true
}

/// Save the state before app terminates. You can save the state whenever you like.
func applicationWillTerminate(_ application: UIApplication) {
    SwiftyState().save()
}
```

This is enough to use SwiftyState hovever if you want to use the debugger, you need to make a way to launch it. The recommended way is to listen for device shake. To do this add the following line to your main ViewController.

```Swift
override func viewDidLoad() {
    super.viewDidLoad()
    // Enable SwiftyState Debuggur UI to be displayed when you shake your device.
    // Remove this one before shipping unless you want to expose the debugger to your users
    SwiftyState().debugUIManager().showOnShake(self)

    /// --------- the rest of your code ---- ///
}
```

If you do not wish to use the device shaking, you can launch the debugger by calling `SwiftyState().debugUIManager().showDebugger()`

## Author

Mertol Kasanan, mrtksn at gmail

## License

SwiftyState is available under the MIT license. See the LICENSE file for more info.
