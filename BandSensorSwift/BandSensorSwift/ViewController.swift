//
//  ViewController.swift
//  BandSensorSwift
//
//  Created by Luke Plewa on 5/1/15.
//  Copyright (c) 2015 Luke Plewa. All rights reserved.
//

import UIKit

class ViewController: UIViewController, MSBClientManagerDelegate {

    @IBOutlet weak var txtOutput: UITextView!
    @IBOutlet weak var heartRateLabel: UILabel!
    weak var client: MSBClient?
    var dataString: NSString!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataString = ""
        // Do any additional setup after loading the view, typically from a nib.
        MSBClientManager.sharedManager().delegate = self
        if let client = MSBClientManager.sharedManager().attachedClients().first as? MSBClient {
            self.client = client
            MSBClientManager.sharedManager().connectClient(self.client)
            self.output("Please wait. Connecting to Band...")
        } else {
            self.output("Failed! No Bands attached.")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func submitData() {
        let timestamp = NSDate().timeIntervalSince1970.description
        SRWebClient.POST("https://www.googleapis.com/upload/storage/v1/b/heart_rates/o?uploadType=media&name=" + timestamp + "&key=AIzaSyBkudbg6waooQCWnP7wGnMqr2mZLzuuZhg&authuser=0")
            .data(["HR_DATA":self.dataString,
                   "x-goog-project-id": 737116352223])
            .send({(response:AnyObject!, status:Int) -> Void in
                //this is success part
                println(response)
                }, failure:{(error:NSError!) -> Void in
                    //this is failure part
                    println(error)
            })
    }

    @IBAction func runExampleCode(sender: AnyObject) {
        if let client = self.client {
            if client.isDeviceConnected == false {
                self.output("Band is not connected. Please wait....")
                return
            }
            client.sensorManager.startHearRateUpdatesToQueue(nil, errorRef: nil, withHandler: { (heartRateData: MSBSensorHeartRateData!, error: NSError!) in
                var heartRateString = heartRateData.heartRate.description + " "
                self.heartRateLabel.text = "Heart Rate: " + heartRateString
                self.dataString = self.dataString.stringByAppendingString(heartRateString)
                self.output(heartRateString)
            })
            
            client.sensorManager.startSkinTempUpdatesToQueue(nil, errorRef: nil, withHandler: { (skinData: MSBSensorSkinTempData!, error: NSError!) in
                var outputString = NSString(format: "%+0.2fC ", skinData.temperature) as String
                self.dataString = self.dataString.stringByAppendingString(outputString)
                self.output(outputString)
            })
    
            //Stop HR updates after 120 seconds
            let delay = 120.0 * Double(NSEC_PER_SEC)
            var time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue(), {
                self.output("Stopping data updates...")
                println(self.dataString)
                if let client = self.client {
                    client.sensorManager.stopHeartRateUpdatesErrorRef(nil)
                    client.sensorManager.stopSkinTempUpdatesErrorRef(nil)
                }
                // add in code to submit data
                self.submitData()
                self.dataString = ""
            })
        } else {
            self.output("Band is not connected. Please wait....")
        }
    }
    
    func output(message: String) {
        self.txtOutput.text = NSString(format: "%@\n%@", self.txtOutput.text, message) as String
        let p = self.txtOutput.contentOffset
        self.txtOutput.setContentOffset(p, animated: false)
        self.txtOutput.scrollRangeToVisible(NSMakeRange(self.txtOutput.text.lengthOfBytesUsingEncoding(NSASCIIStringEncoding), 0))
    }
    
    // Mark - Client Manager Delegates
    func clientManager(clientManager: MSBClientManager!, clientDidConnect client: MSBClient!) {
        self.output("Band connected.")
    }
    
    func clientManager(clientManager: MSBClientManager!, clientDidDisconnect client: MSBClient!) {
        self.output(")Band disconnected.")
    }
    
    func clientManager(clientManager: MSBClientManager!, client: MSBClient!, didFailToConnectWithError error: NSError!) {
        self.output("Failed to connect to Band.")
        self.output(error.description)
    }
}

