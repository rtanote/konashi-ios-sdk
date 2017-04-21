//
//  ViewController.swift
//  iPadExample
//
//  Created by Ryo Tagaya on 2017/02/09.
//  Copyright © 2017年 Ryo Tagaya. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        Konashi.initialize()
        Konashi.shared().readyHandler = {() -> Void in
            
            let alert = UIAlertView(title: "hoge", message: "hoge", delegate: nil, cancelButtonTitle: nil)
            alert.show()
            
            Konashi.pinMode(KonashiDigitalIOPin.LED2, mode: KonashiPinMode.output)
            Konashi.digitalWrite(KonashiDigitalIOPin.LED2, value: KonashiLevel.high)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func tapped(_ sender: UIButton) {
        Konashi.find{ peripherals in
            for p in peripherals! {
                if let p_ = p as? CBPeripheral {
                    if p_.name != nil {
                        print(p_.name!)
                    } else {
                        print("unnamed");
                    }
                }
            }
        }
    }

}

