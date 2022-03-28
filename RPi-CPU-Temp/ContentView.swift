//
//  ContentView.swift
//  RPi-CPU-Temp
//
//  Created by wade ryan on 3/22/22.
//

import SwiftUI
import CoreBluetooth
import BlueCapKit
//import Foundation

struct ContentView: View {
//    let manager = CentralManager(options: [CBCentralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.central-manager-documentation" as NSString])

    public enum Orientation {
        case portrait
        case landscape
    }

    
//        let manager = CentralManager(options: [CBCentralManagerOptionRestoreIdentifierKey : "RPiCPUTemp2" as NSString])
           let manager = CentralManager()
    @State var peripheral: Peripheral?

    
//    @State var connectionFuture: FutureStream<Void>
    

    
    public enum AppError : Error {
        case dataCharactertisticNotFound
        case enabledCharactertisticNotFound
        case updateCharactertisticNotFound
        case serviceNotFound
        case invalidState
        case resetting
        case poweredOff
        case unauthorized
        case unsupported
        case unknown
        case unlikely
        case tag10
    }

    @State var tempCharacteristic : Characteristic?
    @State var unitCharacteristic : Characteristic?
    @State var connectionStatusLabel = Text("unknown")
    @State var hostname = Text("Hostname: unknown")
    @State var units = TemperatureUnitType.celsius
    
    var body: some View {
        VStack {

            if (UIDevice.current.orientation.isLandscape ||
                UIDevice.current.orientation.isFlat ||
               !UIDevice.current.orientation.isValidInterfaceOrientation
            ) {

                HStack {
                    Image("icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.vertical, 50.0)
                    VStack {
                        hostname.padding()
                        
                        connectionStatusLabel
                        
                        Picker(selection: $units, label: Text("Units:")) {
                            Text("Fahrenheit").tag(TemperatureUnitType.fahrenheit)
                            Text("Celsius").tag(TemperatureUnitType.celsius)
                        }.onChange(of: units, perform: { (value) in modifyService() } )
                    }
                }

            } else {

                VStack {
                    Image("icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.horizontal, 100.0)

                    hostname.padding()
                    
                    connectionStatusLabel
                    
                    Picker(selection: $units, label: Text("Units:")) {
                        Text("Fahrenheit").tag(TemperatureUnitType.fahrenheit)
                        Text("Celsius").tag(TemperatureUnitType.celsius)
                    }.onChange(of: units, perform: { (value) in modifyService() } )
                }
                
            }

        }.onAppear(perform: activate)
    }

    func modifyService() {
        let serviceUUID = CBUUID(string:RaspberryPi.TemperatureService.uuid)
        let unitCharacteristicUUID = CBUUID(string:RaspberryPi.TemperatureService.unitCharacteristicUUID)

        print("modifying rpi service units to \(units)")
        if (peripheral==nil) {
            if (units==TemperatureUnitType.fahrenheit) {
                units=TemperatureUnitType.celsius
            } else {
                units=TemperatureUnitType.fahrenheit
            }
        } else {
//            peripheral?.discoverServices([CBUUID(TemperatureService.unitCharacteristicUUID)])
            guard let discoveredPeripheral = peripheral else {
                print("e602: unknown error")
                return
            }
            guard let dataCharacteristic = discoveredPeripheral.services(withUUID:serviceUUID)?.first?.characteristics(withUUID:unitCharacteristicUUID)?.first else {
                print("e605 unit characteristic not found")
                return
            }
            unitCharacteristic = dataCharacteristic
            print("modifying unit characteristic")
            
            guard let unit: String = ((units==TemperatureUnitType.fahrenheit) ? "F" : "C") else {
                return;
            }
            
            let writeFuture = self.unitCharacteristic?.write(data:unit.data(using: .utf8)!)

            writeFuture?.onSuccess(completion: { (_) in
                read()
            })
            
//            DispatchQueue.main.async {
//                message(msg: "Discovered characteristic \(dataCharacteristic.uuid.uuidString)")
//            }
        }
        
    }
    
    
    
    func messageTemp(temp: String) {
        let date = Date()
        let calendar = Calendar.current
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        let hh = calendar.component(.hour, from: date)
        let mm = calendar.component(.minute, from: date)
        let ss = calendar.component(.second, from: date)

        let time = String(format:"%04d-%02d-%02d %02d:%02d:%02d", year,month,day, hh,mm,ss)
        message(msg: time+"\nTemperature: " + temp)

    }
    
    func message(msg: String) {
        print(msg)
        connectionStatusLabel = Text(msg)
    }

    func read(){
        //read a value from the characteristic
        let readFuture = self.tempCharacteristic?.read(timeout: 5)
        readFuture?.onSuccess { (_) in
            //the value is in the dataValue property
            
            //let s = String(data:(self.tempCharacteristic?.dataValue)!, encoding: .utf8)
            let s = String(data:(self.tempCharacteristic?.dataValue)!, encoding: .utf8) ?? "unknown"
            
            DispatchQueue.main.async {
                messageTemp(temp: s)
                let unit = s.last!
                if (unit.uppercased()=="F") {
                    units=TemperatureUnitType.fahrenheit
                } else {
                    units=TemperatureUnitType.celsius
                }
            }
        }
        readFuture?.onFailure { (_) in
            message(msg: "read error")
        }
    }
    
    
    func activate() {
        message(msg: "Activating...")
        
        let serviceUUID = CBUUID(string:RaspberryPi.TemperatureService.uuid)
        let tempCharacteristicUUID = CBUUID(string:RaspberryPi.TemperatureService.tempCharacteristicUUID)
        let unitCharacteristicUUID = CBUUID(string:RaspberryPi.TemperatureService.unitCharacteristicUUID)

        


        
        let stateChangeFuture = manager.whenStateChanges()
        print("tag10...")

        let scanFuture = stateChangeFuture.flatMap {
            state -> FutureStream<Peripheral> in switch state {
                case .poweredOn:
                    DispatchQueue.main.async {
                        message(msg:"Scanning...")
                    }
                    //scan for peripherlas that advertise the ec00 service
                    return manager.startScanning(forServiceUUIDs: [serviceUUID], capacity: 10)
                case .poweredOff:
                    print("powered off")
                    throw AppError.poweredOff
                case .unauthorized:
                    print("unauthorized")
                    throw AppError.unauthorized
                case .unsupported:
                    print("unsupported")
                    throw AppError.unsupported
                case .resetting:
                    print("resetting")
                    throw AppError.resetting
                case .unknown:
                    print("state is unknown")
                    //generally this state is ignored
                    throw AppError.unknown
            }
        }
        
        print("tag20...")
        scanFuture.onFailure { error in
            guard let appError = error as? AppError else {
                return
            }
            switch appError {
            case .invalidState:
                print("e201: invalid state")
                break
            case .resetting:
                print("e202: resetting")
                manager.reset()
            case .poweredOff:
                print("e203: powered off")
                break
            case .unknown:
                print("e204: unknown")
                break
            default:
                break;
            }
        }
        
        
        print("tag30...")
        
        //We will connect to the first scanned peripheral
        let connectionFuture = scanFuture.flatMap { p -> FutureStream<Void> in
            //stop the scan as soon as we find the first peripheral
            manager.stopScanning()
            peripheral = p
            guard let peripheral = peripheral else {
                throw AppError.unknown
            }
            DispatchQueue.main.async {
//                message(msg: "Found peripheral \(peripheral.identifier.uuidString). \nTrying to connect...")
                message(msg: "Found peripheral \(peripheral.name)\nwith \(peripheral.services.count) services\nconnecting...")
                hostname = Text("Hostname: "+peripheral.name)
            }
            //connect to the peripheral in order to trigger the connected mode
            return peripheral.connect(connectionTimeout: 20, capacity: 5)
//            return peripheral.connect(connectionTimeout: 20)
        }
        
        
        print("tag40...")
        let discoveryFuture = connectionFuture.flatMap { _ -> Future<Void> in
            guard let peripheral = peripheral else {
                print("e401: unknown error")
                throw AppError.unknown
            }
            return peripheral.discoverServices([serviceUUID])
        }
            
        let temp = discoveryFuture.flatMap { _ -> Future<Void> in
            guard let discoveredPeripheral = peripheral else {
                print("e402: unknown error")
                throw AppError.unknown
            }
            guard let service = discoveredPeripheral.services(withUUID:serviceUUID)?.first else {
                print("e403: servcie not found")
                throw AppError.serviceNotFound
            }
            peripheral = discoveredPeripheral
            DispatchQueue.main.async {
                message(msg: "Discovered service \(service.uuid.uuidString). Trying to discover chracteristics")
            }
            //we have discovered the service, the next step is to discover the "ec0e" characteristic
            return service.discoverCharacteristics([tempCharacteristicUUID,unitCharacteristicUUID])
        }
        
        
        
        print("tag50...")
        /**
         1- checks if the characteristic is correctly discovered
         2- Register for notifications using the dataFuture variable
        */
        let dataFuture = temp.flatMap { _ -> Future<Void> in
            guard let discoveredPeripheral = peripheral else {
                throw AppError.unknown
            }
            guard let dataCharacteristic = discoveredPeripheral.services(withUUID:serviceUUID)?.first?.characteristics(withUUID:tempCharacteristicUUID)?.first else {
                throw AppError.dataCharactertisticNotFound
            }
            tempCharacteristic = dataCharacteristic
            DispatchQueue.main.async {
                message(msg: "Discovered characteristic \(dataCharacteristic.uuid.uuidString)")
            }
            //when we successfully discover the characteristic, we can show the characteritic view
//            DispatchQueue.main.async {
//                self.loadingView.isHidden = true
//                self.characteristicView.isHidden = false
//            }
            //read the data from the characteristic
            self.read()
            //Ask the characteristic to start notifying for value change
            return dataCharacteristic.startNotifying()
            }.flatMap { _ -> FutureStream<Data?> in
                guard let discoveredPeripheral = peripheral else {
                    throw AppError.unknown
                }
                guard let characteristic = discoveredPeripheral.services(withUUID:serviceUUID)?.first?.characteristics(withUUID:tempCharacteristicUUID)?.first else {
                    throw AppError.dataCharactertisticNotFound
                }
                //regeister to recieve a notifcation when the value of the characteristic changes and return a future that handles these notifications
                return characteristic.receiveNotificationUpdates(capacity: 10)
        }
        
        //The onSuccess method is called every time the characteristic value changes
        dataFuture.onSuccess { data in
//            let s = String(data:data!, encoding: .utf8)
            let s = String(data:data!, encoding: .utf8) ?? "unknown"
            
            DispatchQueue.main.async {
                messageTemp(temp: s)
            }
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewInterfaceOrientation(.portrait)
    }
}
