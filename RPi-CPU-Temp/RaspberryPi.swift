//


import Foundation
import CoreBluetooth


// MARK: - TiSensorTag Services -
public struct RaspberryPi {
    public static let uuid = "00000000-710e-4a5b-8d75-3e5b444bc3cf"

    // MARK: - Accelerometer Service -
    public struct TemperatureService  {
        
        // ServiceConfigurable
        public static let uuid = "00000001-710e-4a5b-8d75-3e5b444b3c3f"
        public static let name = "RPi"
        public static let tag  = "CPU Temp Sensor Tag"
        
        public static let tempCharacteristicUUID = "00000002-710e-4a5b-8d75-3e5b444bc3cf"
        public static let unitCharacteristicUUID = "00000003-710e-4a5b-8d75-3e5b444bc3cf"

        
        // data
        public var mode: String
        public var degrees: String
        
        
        
    }

}

