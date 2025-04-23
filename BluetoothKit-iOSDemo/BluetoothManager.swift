//
//  BluetoothManager.swift
//  BluetoothKit-iOSDemo
//
//  Created by Muhammad Ahmad Munir on 15/04/2025.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    public var connectedPeripheral: CBPeripheral?
    private var targetCharacteristic: CBCharacteristic?
    
    @Published var discoveredDevices = [CBPeripheral]()
    @Published var selectedMetric: MetricType = .weight
    @Published var isConnected = false
    @Published var isScanning = false
    @Published var metricsHistory: [BodyMetricsModel] = []
    @Published var ssid = ""
    @Published var password = ""
    @Published var connectionStatus = "Disconnected"
    @Published var lastWeightMeasurement: String = "No data"
    
    enum MetricType: String, CaseIterable {
        case weight = "Weight"
        case bodyFat = "Body Fat"
    }
    
    let serviceUUID = CBUUID(string: "0000FFE0-0000-1000-8000-00805F9B34FB")
    let characteristicUUID = CBUUID(string: "0000FFE1-0000-1000-8000-00805F9B34FB")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
        loadCredentials()
        generateDemoData()
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            connectionStatus = "Bluetooth unavailable"
            return
        }
        
        discoveredDevices.removeAll()
        isScanning = true
        connectionStatus = "Scanning..."
        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.stopScanning()
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        connectionStatus = discoveredDevices.isEmpty ? "No devices found" : "Scan complete"
    }
    
    func connect(to peripheral: CBPeripheral) {
        connectionStatus = "Connecting..."
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    func sendWifiCredentials() {
        guard let characteristic = targetCharacteristic else {
            connectionStatus = "No characteristic found"
            return
        }
        
        let credentials = "\(ssid):\(password)"
        guard let data = credentials.data(using: .utf8) else {
            connectionStatus = "Invalid credentials"
            return
        }
        
        connectedPeripheral?.writeValue(data, for: characteristic, type: .withResponse)
        saveCredentials()
        connectionStatus = "Credentials sent"
        
        // Simulate receiving data after credentials are sent
        simulateDataReception()
    }
    
    private func simulateDataReception() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.generateDemoData()
            self.lastWeightMeasurement = "67.9 kg (17.5% fat)"
            self.connectionStatus = "Data received"
        }
    }
    
    private func generateDemoData() {
        var demoMetrics = [BodyMetricsModel]()
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Generate 7 days of data
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: currentDate)!
            let weight = Double.random(in: 67.0...69.0).rounded(toPlaces: 1)
            let bodyFat = Double.random(in: 17.0...18.5).rounded(toPlaces: 1)
            demoMetrics.append(BodyMetricsModel(date: date, weight: weight, bodyFat: bodyFat))
        }
        
        metricsHistory = demoMetrics.sorted(by: { $0.date < $1.date })
        lastWeightMeasurement = "\(metricsHistory.last?.weight ?? 0) kg (\(metricsHistory.last?.bodyFat ?? 0)% fat)"
    }
    
    
    private func loadCredentials() {
        ssid = UserDefaults.standard.string(forKey: "wifiSSID") ?? ""
        password = UserDefaults.standard.string(forKey: "wifiPassword") ?? ""
    }
    
    func saveCredentials() {
        UserDefaults.standard.set(ssid, forKey: "wifiSSID")
        UserDefaults.standard.set(password, forKey: "wifiPassword")
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            connectionStatus = "Bluetooth ready"
        case .poweredOff:
            connectionStatus = "Bluetooth off"
        case .unauthorized:
            connectionStatus = "Bluetooth unauthorized"
        case .unsupported:
            connectionStatus = "Bluetooth unsupported"
        default:
            connectionStatus = "Bluetooth unavailable"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredDevices.append(peripheral)
            connectionStatus = "Found \(peripheral.name ?? "device")"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        connectedPeripheral = peripheral
        connectionStatus = "Connected to \(peripheral.name ?? "device")"
        peripheral.discoverServices([serviceUUID])
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == characteristicUUID {
                targetCharacteristic = characteristic
                connectionStatus = "Ready to send credentials"
            }
        }
    }
}



// Add this extension for date formatting
extension Date {
    func formattedChartDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
}

// Add this extension for double rounding
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
