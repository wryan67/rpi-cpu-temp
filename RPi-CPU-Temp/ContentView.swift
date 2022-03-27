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
    let manager = CentralManager(options: [CBCentralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.central-manager-documentation" as NSString])

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
    


    @State var connectionStatusLabel = Text("unknown")
    //Label("unknown", systemImage: "42.circle")

    //    var connectionStatusLabel: Label<"unknown", NULL>
    
    var body: some View {
        VStack {
            Text("Hello, world!")
                .padding()
            
            connectionStatusLabel
            
        }.onAppear(perform: load)
    }
    
    

    func load() {
        print("load...")
        connectionStatusLabel = Text("loading...")
        
        let serviceUUID = CBUUID(string:RaspberryPi.TemperatureService.uuid)
        let deviceUUID = CBUUID(string:RaspberryPi.uuid)
        var peripheral: Peripheral?
        let tempCharacteristicUUID = CBUUID(string:RaspberryPi.TemperatureService.tempCharacteristicUUID)
       
        let manager = CentralManager(options: [CBCentralManagerOptionRestoreIdentifierKey : "CentralMangerKey" as NSString])
        
        let stateChangeFuture = manager.whenStateChanges()
        print("tag10...")

        let scanFuture = stateChangeFuture.flatMap {
            state -> FutureStream<Peripheral> in switch state {
                case .poweredOn:
                    DispatchQueue.main.async {
                        let message = "scanning<\(deviceUUID.uuidString)>..."
                        connectionStatusLabel = Text(message)
                        print(message)
                    }
                    //scan for peripherlas that advertise the ec00 service
                    return manager.startScanning(forServiceUUIDs: [deviceUUID], capacity: 10)
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
                let msg="Found peripheral \(peripheral.identifier.uuidString). \nTrying to connect..."
                print(msg)
                connectionStatusLabel = Text(msg)
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
            }.flatMap { _ -> Future<Void> in
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
                    let msg="Discovered service \(service.uuid.uuidString). Trying to discover chracteristics"
                    print(msg)
                    connectionStatusLabel = Text(msg)                }
                //we have discovered the service, the next step is to discover the "ec0e" characteristic
                return service.discoverCharacteristics([tempCharacteristicUUID])
        }
        
        
        
        print("tag50...")
        /**
         1- checks if the characteristic is correctly discovered
         2- Register for notifications using the dataFuture variable
        */
        let dataFuture = discoveryFuture.flatMap { _ -> Future<Void> in
            guard let discoveredPeripheral = peripheral else {
                throw AppError.unknown
            }
            guard let dataCharacteristic = discoveredPeripheral.services(withUUID:serviceUUID)?.first?.characteristics(withUUID:tempCharacteristicUUID)?.first else {
                throw AppError.dataCharactertisticNotFound
            }
            DispatchQueue.main.async {
                let msg="Discovered characteristic \(dataCharacteristic.uuid.uuidString). "
                print(msg)
                connectionStatusLabel = Text(msg)
            }
            throw AppError.tag10
        }
    
        
        //The onSuccess method is called every time the characteristic value changes
//        dataFuture.onSuccess { data in
//            let s = String(data:data!, encoding: .utf8)
//            DispatchQueue.main.async {
//                self.notifiedValueLabel.text = "notified value is \(String(describing: s))"
//            }
//        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
