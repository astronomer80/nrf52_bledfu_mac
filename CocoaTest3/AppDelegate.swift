//
//  AppDelegate.swift
//  CocoaTest3
//
//  Created by chiara on 1/10/17.
//  Copyright © 2017 Arduino S.r.l. All rights reserved.
//

import Cocoa
import iOSDFULibrary
import CoreBluetooth

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {

    func logWrite(message: String){
        print (message)
        //let destinationPath = NSTemporaryDirectory() + "/Users/chiara/Desktop/my_file.txt"
        let destinationPath = "/Users/chiara/Desktop/my_file.txt"
        let fileURL = try! FileManager.default.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("my_file1.txt")
        
        if let outputStream = OutputStream(url: fileURL, append: true) {
            outputStream.open()
            let text = message + "\n"
            let bytesWritten = outputStream.write(text, maxLength: text.lengthOfBytes(using: String.Encoding.utf8))//  .write(text, _maxLenght:20)
            if bytesWritten < 0 { print("write failure") }
            outputStream.close()
        } else {
            print("Unable to open file")
        }

        do {
            try message.write(toFile: destinationPath, atomically: true, encoding: String.Encoding.utf8)
            //try test.write(toFile: destinationPath, atomically: false, encoding: String.Encoding.utf8)
        }
        catch {/* error handling here */}
                //let written = myTextString.write(toFile: destinationPath, atomically: true, encoding: NSUTF8StringEncoding)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        logWrite(message: "START")
        centralManager = CBCentralManager(delegate: self, queue: nil)
    
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    //MARK: - Class properties
    var centralManager              : CBCentralManager!
    var legacyDfuServiceUUID        : CBUUID
    var secureDfuServiceUUID        : CBUUID
    var selectedPeripheral          : CBPeripheral!
    var selectedPeripheralIsSecure  : Bool?
    var discoveredPeripherals       : [CBPeripheral]?
    var securePeripheralMarkers     : [Bool]?
    
    required override init() {
        //Initialize CentralManager and DFUService UUID
        centralManager = CBCentralManager()
        legacyDfuServiceUUID    = CBUUID(string: "00001530-1212-EFDE-1523-785FEABCD123")
        secureDfuServiceUUID    = CBUUID(string: "FE59")
        //super.init(coder: aDecoder)
        super.init()
        centralManager.delegate = self
        discoveredPeripherals = [CBPeripheral]()
        securePeripheralMarkers = [Bool]()
    }
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        //if central.state == CBCentralManagerState.poweredOn {
        //centralManager.scanForPeripheralsWithServices(nil, options: nil)
        
        switch (central.state)
        {
        case.unsupported:
            logWrite(message: "BLE is not supported")
        case.unauthorized:
            logWrite(message:"BLE is unauthorized")
        case.unknown:
            logWrite(message:"BLE is Unknown")
        case.resetting:
            logWrite(message:"BLE is Resetting")
        case.poweredOff:
            logWrite(message:"BLE service is powered off")
        case.poweredOn:
            logWrite(message:"BLE service is powered on. Scanning for peripherals...")
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        default:
            logWrite(message: "default state")
            
        }
    }
    
    //Start DFU procedure
    func startDFU(){
        logWrite(message: "Start DFU")
        // Do any additional setup after loading the view.
        let url = URL(string: "file:///Users/chiara/Documents/app_blink_package_500/nrf52832_xxaa_s132.bin")
        let datUrl = URL(string: "file:///Users/chiara/Documents/app_blink_package_500/nrf52832_xxaa_s132.dat")
        
        
        //let selectedFirmware = DFUFirmware(urlToZipFile:url!)
        let selectedFirmware = DFUFirmware(urlToBinOrHexFile: url!, urlToDatFile: datUrl!, type: DFUFirmwareType.application)
        
        //let selectedFirmware = DFUFirmware
        
        //let initiator = DFUServiceInitiator(centralManager: self.centralManager, twet: self.selectedPeripheral).withFirmwareFile(selectedFirmware)
        
        let initiator = DFUServiceInitiator(centralManager: self.centralManager!, target: self.selectedPeripheral)
        initiator.with(firmware: selectedFirmware!)
        // Optional:
        //initiator.forceDfu = true;
        //initiator.logger
        
        //initiator.forceDfu = true/false; // default false
        // initiator.packetReceiptNotificationParameter = N; // default is 12
        //        initiator.logger = self; // - to get log info
        //        initiator.delegate = self; // - to be informed about current state and errors
        //        initiator.progressDelegate = self; // - to show progress bar
        // initiator.peripheralSelector = ... // the default selector is used
        
        let controller = initiator.start()
        print(controller.debugDescription);
        
        logWrite(message: "Ends uploading")
        
        
    }
    
    
    //    func centralManagerDidUpdateState(central: CBCentralManager!) {
    //
    //    }
    //
    // Launched when the application starts
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        logWrite(message: "Scanning...");
        //If any BLE device is found
        if advertisementData[CBAdvertisementDataServiceUUIDsKey] != nil {
            //Secure DFU UUID
            let secureUUIDString = CBUUID(string: "FE59").uuidString
            let advertisedUUIDstring = ((advertisementData[CBAdvertisementDataServiceUUIDsKey]!) as AnyObject).firstObject as! CBUUID
            if advertisedUUIDstring.uuidString  == secureUUIDString {
                logWrite(message: "Found Secure Peripheral: \(peripheral.name!)")
                if self.discoveredPeripherals?.contains(peripheral) == false {
                    self.discoveredPeripherals?.append(peripheral)
                    self.securePeripheralMarkers?.append(true)
                    //discoveredPeripheralsTableView.reloadData()
                    
                    //Start DFU procedure
                    self.startDFU()

                }
            }else{
                logWrite(message: "Found Legacy Peripheral: \(peripheral.name!) \(peripheral.identifier.uuidString)")
                if self.discoveredPeripherals?.contains(peripheral) == false {
                    self.discoveredPeripherals?.append(peripheral)
                    self.securePeripheralMarkers?.append(false)
                    logWrite(message: "Test1")
                    
                    self.selectedPeripheral = peripheral
                    
                    //Start DFU procedure
                    self.startDFU()
                    //discoveredPeripheralsTableView.reloadData()
                }
            }
        }
    }


}

