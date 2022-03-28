//
//  TemperatureUnits.swift
//  RPi-CPU-Temp
//
//  Created by wade ryan on 3/27/22.
//

import Foundation
import SwiftUI
import Combine

public enum TemperatureUnitType: String, CaseIterable {
    case fahrenheit = "Fahrenheit"
    case celsius = "Celsius"
}

