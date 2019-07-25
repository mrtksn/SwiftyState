//
//  SwiftyStateDebuggerViewController.swift
//  SmokeFreeNetwork
//
//  Created by Mertol Kasanan on 02/07/2019.
//  Copyright © 2019 Mertol Kasanan. All rights reserved.
//

import UIKit


/// This UIViewController that cat init the UI
public class SwiftyStateDebugUIManager: UIViewController {
    var containerVC : UIViewController?
    override public func viewDidLoad() {
        super.viewDidLoad()
    }
    override public func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard let parent = containerVC else {
            NSLog("The contaiber VC for SwiftyState Debugger is nil, the Debugger UI cannot be loaded")
            return
        }
        SwiftyState().debugUIManager().showDebugger(parent)
       
    }
 
    /// Display the UI when device is shaken
    @discardableResult public
    func showOnShake(_ parent: UIViewController)->SwiftyStateDebugUIManager{
        NSLog("Init ShowOnShake", parent)
        self.containerVC = parent
        self.view.frame = CGRect.zero
        parent.addChild(self)
        parent.view.addSubview(self.view)
        return self
    }
    
    /// Stop listening for shaking by removing the view and freeing up resources
    func cancelShowOnShake(){
        self.removeFromParent()
    }
    
    /// Show the debugger UI
    public func showDebugger(_ parent: UIViewController){
  
        
        let debugUIVC : UIViewController? = SwiftyState().getDebugUI() //If the showDebugger is called when the debugger is already displayed
        
        if debugUIVC == nil {
            let bundle = Bundle(for:SwiftyStateDebuggerViewController.self)
            let debuggerUI = SwiftyStateDebuggerViewController(nibName: "SwiftyStateDebuggerViewController", bundle: bundle)
            

            
            debuggerUI.initUI(parent)
            SwiftyState().setDebugUI(debuggerUI)
        }
    }
    
    /// Close the debugger UI and free up resources
    func closeDebugger(){
        SwiftyState().getDebugUI()?.closeUI()
     //   self.machineState.debugUI = nil
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
         NSLog("Debug UI Removed from main VC")
        self.cancelShowOnShake()
        
    }
    
    deinit {
        NSLog("DebugManager UI deinit")
    }
}



/// This passes touch events down, making the debugger view "transparent"
public class SwiftyPassthroughView: UIView {
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
}

/// The UI Size
///
/// - full: Fully expaned UI
/// - compact: compacted UI
public enum SwiftyDebuggerSize{
    case full
    case compact
}

/// Actions of the debugger UI
///
/// - replaceState: replaces the state with the provided state
public enum SwiftyDebuggerAction : SwiftyAction{
 
    
    public func reducer(state: SwiftyStateStore) -> SwiftyStateStore {
        var finalState = state
        switch self {
        case .replaceState(let newState):
            finalState = newState
        }
        //finalState = AvailableSwiftyActions.ChatActions.reducer(.increaseId(by: 10))(state: finalState)
 
        return finalState
    }
    
    case replaceState(_ state : SwiftyStateStore)
}

/// UIViewController of the debugger UI
public class SwiftyStateDebuggerViewController: UIViewController {
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        NSLog("Debugger UI Init from Xib")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NSLog("Debugger UI Init from coder")
    }
    
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    var sub : SwiftySubscription?

    /// An array of the states over time
    var history = [SwiftyStateStoreHistory]()
    /// Picked state
    var currHistoryIndex = 0
    /// This is true if the user is looking at the most recent state. If true, the slider will be moved to max to keep up with the newly added states
    var sliderMaxedOut : Bool = true
    
    var UISize : SwiftyDebuggerSize = .compact
    
    @IBOutlet weak var historySlider: UISlider!
    @IBOutlet weak var JSONView: UITextView!
    @IBOutlet weak var actionView: UITextView!
    @IBOutlet weak var engineSwitch: UISwitch!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var indexLabel: UILabel!
    @IBOutlet weak var storeContainer: UIView!
    
    @IBOutlet weak var navigationBarView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewCompactConstrain: NSLayoutConstraint!
    @IBOutlet weak var sizeButton: UIBarButtonItem!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.headerView.layer.shadowColor = UIColor.black.cgColor
        self.headerView.layer.shadowOpacity = 0.3
        self.headerView.layer.shadowOffset = .zero
        self.headerView.layer.shadowRadius = 10
        self.headerView.layer.shouldRasterize = true
        self.headerView.layer.rasterizationScale = UIScreen.main.scale
        self.headerView.layer.cornerRadius = 20
        self.headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.headerView.clipsToBounds = false
        
        self.storeContainer.layer.cornerRadius = 20
        self.navigationBarView.layer.cornerRadius = 20
        self.navigationBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.navigationBarView.clipsToBounds = true
        
        
        
        SwiftyState().startDebug()
        // Do any additional setup after loading the view.
        
        self.sub = SwiftyState().subscribe { [weak self] in
            let _ = $0
            let _ = $1
            self?.history = SwiftyState().getHistory()
            self?.historySlider.maximumValue = Float(self?.history.count ?? 1)
            
            //Update the slider max every time
            guard let totalHistoryPoints = self?.history.count else {
                return
            }
            
            if self!.sliderMaxedOut {
               self?.showState(totalHistoryPoints, autoApply: false)
            }
            
            if self?.currHistoryIndex == 0 {
                self?.showState(totalHistoryPoints, autoApply: false)
            }
            
            self?.updateCountIndicator()
            
        }
        
        self.sub?.hotStart()
        self.currHistoryIndex = history.count - 1
        let engineConfig = SwiftyState().getConfig()
        self.engineSwitch.isOn = engineConfig.engineOn
        
    }
    
 
    /// attach the UI to the view hierarchy
    ///
    /// - Parameter containerVC: The ViewController where the UI will attach
    func initUI(_ containerVC: UIViewController){
        let frame = containerVC.view.frame

        self.view.frame = frame.offsetBy(dx: 0, dy: 150)
        self.view.alpha = 0
        
        containerVC.addChild(self)
        containerVC.view.addSubview(self.view)
        
        UIView.animate(withDuration: 0.5) {[weak self] in
            self?.view.frame.origin = CGPoint.zero
            self?.view.alpha = 1.0
            self?.view.layoutIfNeeded()
        }
        
    }
    
    /// close the UI and free up the resources
    func closeUI(){
        
        UIView.animate(withDuration: 0.5, animations: {[weak self] in
            guard let currOffset = self?.headerView.frame.origin.y else {
                return
            }
            self?.view.frame.origin = CGPoint(x: 0, y: UIScreen.main.bounds.height - currOffset)
            self?.view.alpha = 0
        }) { [weak self] in
            let _ = $0
            self?.view.removeFromSuperview()
            self?.removeFromParent()
           
        }
        

    }
    
    /// Show the state in the JSONView
    ///
    /// - Parameter index: index of the state to show. It must be within the range of the state history
    /// - Parameter autoApply: should the state be applied or only shown?
    func showState(_ index : Int, autoApply : Bool = true){
       
        /// If the user is viewing the most recent state, mark it
        if index != self.history.count{
            self.sliderMaxedOut = false
        }else{
            self.sliderMaxedOut = true
        }
        
        /// If the requested state is already displayed, do not proceed
        let newIndex = index >= 1 ? (index <= self.history.count ? index : self.history.count) : 1
        if self.currHistoryIndex == newIndex {
            return
        }
        self.currHistoryIndex = newIndex
        
        let historyPoint = self.getSelectedHistoricalState()
     
        
        let state = historyPoint.state
        self.JSONView.text = state.toJSON()
        self.actionView.text = historyPoint.action
        
        if !historyPoint.valid {
            self.actionView.textColor = .red
        }else{
            self.actionView.textColor = .black
        }
        
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        
        self.dateLabel.text = "⏱\(dateFormatter.string(from: historyPoint.date))"
        
        
        if Int(self.historySlider.value) != newIndex {
            self.historySlider.value = Float(newIndex)
        }
        
        self.JSONView.text = state.toJSON()
        
        
        self.updateCountIndicator()
        
        if autoApply{
            applyState(state)
        }
    }
    
    /// Update the history count label
    func updateCountIndicator(){
        self.indexLabel.text = "\(self.currHistoryIndex) of \(self.history.count)"
    }
    
    /// Get the currently selected state
    ///
    /// - Returns: Returns a historical state point
    func getSelectedHistoricalState()->SwiftyStateStoreHistory{
            let newIndex = self.currHistoryIndex - 1
                return self.history[newIndex]
    }
    

    /// Reflect the provided state to the App state
    ///
    /// - Parameter state: the state object that will be applied
    /// - Parameter addToHistory: Should the state be added to the history or only applied
    func applyState(_ state : SwiftyStateStore, addToHistory : Bool = false){
        /// Make sure that we only apply valid states
        if !SwiftyState().validateState(state) {
            return
        }
        if !addToHistory {
            SwiftyState().stopDebug()
        }
        SwiftyState().action(a: SwiftyDebuggerAction.replaceState(state))
        SwiftyState().startDebug()
    }
    
    /// Switch between UI size modes
    func changeUISize(){
        
        let newPriority : Float = self.UISize == .compact ? 8 : 11
        
        
        self.UISize = (self.UISize == .compact) ? .full : .compact
        if self.UISize == .full {
            self.sizeButton.title = "Less ⇩"
        }else{
             self.sizeButton.title = "More ⇪"
        }
        
        UIView.animate(withDuration: 0.5) {[weak self] in
            //
            self?.headerViewCompactConstrain.priority = UILayoutPriority(rawValue: newPriority)
            self?.view.layoutIfNeeded()
        }
        
    }
    
    /// Make the view translucent
    func makeTranslucent(){
        UIView.animate(withDuration: 0.2) {[weak self] in
            self?.view.alpha = 0.5
        }
    }
    /// make the view Opaque
    func makeOpaque(){
        UIView.animate(withDuration: 0.2) {[weak self] in
            self?.view.alpha = 1.0
        }
    }
    
    @IBAction func undoAction(_ sender: Any) {
        let newIndex = self.currHistoryIndex - 1
        self.showState(newIndex)

    }
    @IBAction func redoAction(_ sender: Any) {
        let newIndex = self.currHistoryIndex + 1
        self.showState(newIndex)
    }
  
    @IBAction func sliderChanged(_ sender: UISlider) {
       let id = Int(sender.value)
        self.showState(id)
        
    }
    @IBAction func sliderStart(_ sender: UISlider) {
        if self.UISize == .compact {
            self.makeTranslucent()
        }
    }
    @IBAction func sliderEnd(_ sender: Any) {
        self.makeOpaque()
    }
    
 
    /// Switch the Engine On and OFF. When switched on, the selected state will be applied
    ///
    /// - Parameter sender: an UISwitch
    @IBAction func switchEngine(_ sender: UISwitch) {
        if sender.isOn{
            SwiftyState().startEngine()
            self.applyState(self.getSelectedHistoricalState().state, addToHistory: true)
        }else{
            SwiftyState().stopEngine()
        }
    }
    @IBAction func close(_ sender: Any) {
        self.closeUI()
    }
    @IBAction func changeSize(_ sender: Any) {
        self.changeUISize()
    }
    
    deinit {
        NSLog("DebuggerUI Deinit")
        self.sub?.unsubscribe()
        /// The current state is added to the history
        let finalState = SwiftyState().getRawState()
        self.applyState(finalState, addToHistory: true)
   
    
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
