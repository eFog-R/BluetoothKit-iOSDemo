//
//  BodyMetricsModel.swift
//  BluetoothKit-iOSDemo
//
//  Created by Muhammad Ahmad Munir on 15/04/2025.
//

import Foundation

struct BodyMetricsModel: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    let bodyFat: Double
}
