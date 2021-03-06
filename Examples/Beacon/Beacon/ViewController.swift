//
//  ViewController.swift
//  Beacon
//
//  Created by Troy Stribling on 4/13/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreBluetooth
import BlueCapKit

class ViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet var nameTextField             : UITextField!
    @IBOutlet var uuidTextField             : UITextField!
    @IBOutlet var majorTextField            : UITextField!
    @IBOutlet var minorTextField            : UITextField!
    @IBOutlet var generateUUIDButton        : UIButton!
    @IBOutlet var startAdvertisingSwitch    : UISwitch!
    @IBOutlet var startAdvertisingLabel     : UILabel!
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.startAdvertisingLabel.textColor = UIColor.lightGrayColor()
        self.startAdvertisingSwitch.on = false
        self.setUI()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func generateUUID(sender:AnyObject) {
        let uuid = NSUUID()
        self.uuidTextField.text = uuid.UUIDString
        BeaconStore.setBeaconUUID(uuid)
        self.setUI()
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        return self.addBeacon(textField)
    }
    
    func addBeacon(textField:UITextField) -> Bool {
        let enteredUUID = self.uuidTextField.text
        let enteredName = self.nameTextField.text
        let enteredMajor = self.majorTextField.text
        let enteredMinor = self.minorTextField.text
        if let enteredName = self.nameTextField.text, enteredMajor = self.majorTextField.text, enteredMinor = self.minorTextField.text
            where !enteredName.isEmpty && !enteredMinor.isEmpty && !enteredMajor.isEmpty {
            if let minor = enteredMinor.toInt(),  major = enteredMajor.toInt() {
                if minor < 65536 && major < 65536 {
                    if let enteredUUID = self.uuidTextField.text where !enteredUUID.isEmpty {
                        if let uuid = NSUUID(UUIDString:enteredUUID), minor = enteredMinor.toInt(),  major = enteredMajor.toInt() {
                            BeaconStore.setBeaconUUID(uuid)
                        } else {
                            self.presentViewController(UIAlertController.alertOnErrorWithMessage("UUID '\(enteredUUID)' is Invalid"), animated:true, completion:nil)
                            self.startAdvertisingSwitch.on = false
                            return false
                        }
                    }
                    BeaconStore.setBeaconConfig([UInt16(minor), UInt16(major)])
                    BeaconStore.setBeaconName(enteredName)
                    textField.resignFirstResponder()
                    self.setUI()
                    return true
                } else {
                    self.presentViewController(UIAlertController.alertOnErrorWithMessage("major and minor must be less than 65536"), animated:true, completion:nil)
                    return false
                }
            } else {
                self.presentViewController(UIAlertController.alertOnErrorWithMessage("major and minor not convertable to a number"), animated:true, completion:nil)
                return false
            }
        } else {
            return false
        }
    }
    
    @IBAction func toggleAdvertise(sender:AnyObject) {
        let manager = PeripheralManager.sharedInstance
        if manager.isAdvertising {
            let stopAdvertiseFuture = manager.stopAdvertising()
            stopAdvertiseFuture.onSuccess {
                self.presentViewController(UIAlertController.alertWithMessage("stoped advertising"), animated:true, completion:nil)
            }
            stopAdvertiseFuture.onFailure {error in
                self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
            }
        } else {
            // Start advertising on bluetooth power on
            if let beaconRegion = self.createBeaconRegion() {
                let startAdvertiseFuture = manager.powerOn().flatmap{ _ -> Future<Void> in
                    manager.startAdvertising(beaconRegion)
                }
                startAdvertiseFuture.onSuccess {
                    self.presentViewController(UIAlertController.alertWithMessage("powered on and started advertising"), animated:true, completion:nil)
                }
                startAdvertiseFuture.onFailure {error in
                    self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                    self.startAdvertisingSwitch.on = false
                }
            }
            // stop advertising on bluetooth power off
            let powerOffFuture = manager.powerOff().flatmap { _ -> Future<Void> in
                manager.stopAdvertising()
            }
            powerOffFuture.onSuccess {
                self.startAdvertisingSwitch.on = false
                self.startAdvertisingSwitch.enabled = false
                self.startAdvertisingLabel.textColor = UIColor.lightGrayColor()
                self.presentViewController(UIAlertController.alertWithMessage("powered off and stopped advertising"), animated:true, completion:nil)
            }
            powerOffFuture.onFailure {error in
                self.startAdvertisingSwitch.on = false
                self.startAdvertisingSwitch.enabled = false
                self.startAdvertisingLabel.textColor = UIColor.lightGrayColor()
                self.presentViewController(UIAlertController.alertWithMessage("advertising failed"), animated:true, completion:nil)
            }
            // enable controls when bluetooth is powered on again after stop advertising is successul
            let powerOffFutureSuccessFuture = powerOffFuture.flatmap { _ -> Future<Void> in
                manager.powerOn()
            }
            powerOffFutureSuccessFuture.onSuccess {
                self.startAdvertisingSwitch.enabled = true
                self.startAdvertisingLabel.textColor = UIColor.blackColor()
            }
            // enable controls when bluetooth is powered on again after stop advertising fails
            let powerOffFutureFailedFuture = powerOffFuture.recoverWith { _  -> Future<Void> in
                manager.powerOn()
            }
            powerOffFutureFailedFuture.onSuccess {
                if PeripheralManager.sharedInstance.poweredOn {
                    self.startAdvertisingSwitch.enabled = true
                    self.startAdvertisingLabel.textColor = UIColor.blackColor()
                }
            }
        }
    }

    func createBeaconRegion() -> BeaconRegion? {
        if let name = BeaconStore.getBeaconName(), uuid = BeaconStore.getBeaconUUID() {
            let config = BeaconStore.getBeaconConfig()
            if config.count == 2 {
                return BeaconRegion(proximityUUID:uuid, identifier:name, major:config[1], minor:config[0])
            } else {
                self.presentViewController(UIAlertController.alertOnErrorWithMessage("configuration invalid"), animated:true, completion:nil)
                return nil
            }
        } else {
            self.presentViewController(UIAlertController.alertOnErrorWithMessage("configuration invalid"), animated:true, completion:nil)
            return nil
        }
    }
    
    func setUI() {
        var uuidSet = false
        if let uuid = BeaconStore.getBeaconUUID() {
            self.uuidTextField.text = uuid.UUIDString
            uuidSet = true
        }
        var nameSet = false
        if let name = BeaconStore.getBeaconName() {
            self.nameTextField.text = name
            nameSet = true
        }
        var majoMinorSet = false
        let beaconConfig = BeaconStore.getBeaconConfig()
        if beaconConfig.count == 2 {
            self.minorTextField.text = "\(beaconConfig[0])"
            self.majorTextField.text = "\(beaconConfig[1])"
            majoMinorSet = true
        }
        if uuidSet && nameSet && majoMinorSet {
            self.startAdvertisingLabel.textColor = UIColor.blackColor()
            self.startAdvertisingSwitch.enabled = true
        } else {
            self.startAdvertisingLabel.textColor = UIColor.lightGrayColor()
            self.startAdvertisingSwitch.enabled = false
        }
    }
}
