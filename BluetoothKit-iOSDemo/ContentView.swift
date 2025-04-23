//
//  ContentView.swift
//  BluetoothKit-iOSDemo
//
//  Created by Muhammad Ahmad Munir on 15/04/2025.
//

import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    connectionSection
                    credentialsSection
                    measurementSection
                    metricSelector
                    chartSection
                    deviceList
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Wi-Fi Scale Monitor")
        }
    }
    
    private var connectionSection: some View {
        VStack {
            HStack {
                Circle()
                    .fill(bluetoothManager.isConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(bluetoothManager.connectionStatus)
            }
            
            if !bluetoothManager.isConnected {
                Button(action: {
                    bluetoothManager.startScanning()
                }) {
                    HStack {
                        Image(systemName: "dot.radiowaves.left.and.right")
                        Text(bluetoothManager.isScanning ? "Scanning..." : "Scan Devices")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(bluetoothManager.isScanning)
            }
        }
    }
    
    private var credentialsSection: some View {
        Group {
            TextField("Wi-Fi SSID", text: $bluetoothManager.ssid)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disableAutocorrection(true)
                .autocapitalization(.none)
            
            SecureField("Wi-Fi Password", text: $bluetoothManager.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if bluetoothManager.isConnected {
                Button("Send Credentials") {
                    bluetoothManager.sendWifiCredentials()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
    
    private var measurementSection: some View {
        VStack {
            Text("Last Measurement")
                .font(.headline)
            Text(bluetoothManager.lastWeightMeasurement)
                .font(.title2)
        }
    }
    
    private var metricSelector: some View {
        Picker("Metric", selection: $bluetoothManager.selectedMetric) {
            ForEach(BluetoothManager.MetricType.allCases, id: \.self) { metric in
                Text(metric.rawValue).tag(metric)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    
    private var chartSection: some View {
        VStack {
            Text("Body Metrics Trend")
                .font(.headline)
                .padding(.bottom)
            
            if bluetoothManager.metricsHistory.isEmpty {
                Text("No data available")
                    .frame(height: 300)
            } else {
                Chart(bluetoothManager.metricsHistory) { metric in
                    LineMark(
                        x: .value("Date", metric.date),
                        y: .value("Value", bluetoothManager.selectedMetric == .weight ? metric.weight : metric.bodyFat)
                    )
                    .foregroundStyle(bluetoothManager.selectedMetric == .weight ? .blue : .green)
                    
                    PointMark(
                        x: .value("Date", metric.date),
                        y: .value("Value", bluetoothManager.selectedMetric == .weight ? metric.weight : metric.bodyFat)
                    )
                    .annotation(position: .top) {
                        Text(bluetoothManager.selectedMetric == .weight ?
                             "\(metric.weight, specifier: "%.1f")kg" :
                                "\(metric.bodyFat, specifier: "%.1f")%")
                        .font(.caption2)
                        .rotationEffect(.degrees(-45))
                        .offset(y: -10)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(
                            bluetoothManager.selectedMetric == .weight ?
                            "\(value.as(Double.self) ?? 0, specifier: "%.1f") kg" :
                                "\(value.as(Double.self) ?? 0, specifier: "%.1f")%"
                        )
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisTick()
                        if let date = value.as(Date.self) {
                            AxisValueLabel(date.formattedChartDate())
                        }
                    }
                }
                .frame(height: 300)
                .padding()
            }
        }
    }
    
    
    private var deviceList: some View {
        VStack {
            Text("Discovered Devices")
                .font(.headline)
            
            if bluetoothManager.discoveredDevices.isEmpty {
                Text(bluetoothManager.isScanning ? "Searching..." : "No devices found")
                    .frame(height: 100)
            } else {
                List(bluetoothManager.discoveredDevices, id: \.identifier) { device in
                    Button(action: {
                        bluetoothManager.connect(to: device)
                    }) {
                        HStack {
                            Image(systemName: "scalemass")
                            Text(device.name ?? "Unknown Device")
                            Spacer()
                            if bluetoothManager.connectedPeripheral?.identifier == device.identifier {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
    }
}

#Preview {
    ContentView()
}
