//
//  SecondViewController.swift
//  SwiftyState_Example
//
//  Created by Mertol Kasanan on 25/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import SwiftyState

class SecondViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        SwiftyState().debugUIManager().showOnShake(self)
        // Do any additional setup after loading the view.
    }
    
    @IBAction func showDbg(_ sender: Any) {
        SwiftyState().debugUIManager().showDebugger(self)
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
