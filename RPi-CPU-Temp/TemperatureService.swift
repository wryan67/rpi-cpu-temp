//


import Foundation
import CoreBluetooth


public struct RaspberryPi {

    public struct TemperatureService  {
        
        // ServiceConfigurable
        public static let uuid = "00000001-9233-4a5b-8d75-3e5b444bc3cf"
        public static let name = "RPi"
        public static let tag  = "CPU Temp Sensor Tag"
        
        public static let tempCharacteristicUUID = "00000002-9233-4a5b-8d75-3e5b444bc3cf"
        public static let unitCharacteristicUUID = "00000003-9233-4a5b-8d75-3e5b444bc3cf"
       
        // data
        public var mode: String
        public var degrees: String
        
    }
}

