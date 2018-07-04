//
//  ViewController.swift
//  NetTools
//
//  Created by 储诚鹏 on 2018/6/29.
//  Copyright © 2018年 储诚鹏. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let realNet = RealNetConnection.instance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        realNet.start { (status) in
        
            print("🌹 \(status.0) 🌹")
        }
        
       // realNet.oneMonitoring()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }

}

