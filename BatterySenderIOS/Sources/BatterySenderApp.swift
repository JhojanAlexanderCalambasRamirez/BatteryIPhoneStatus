import SwiftUI

@main
struct BatterySenderApp: App {
    @StateObject private var batteryManager = BatteryManager()
    @StateObject private var networkSender = NetworkSender()

    var body: some Scene {
        WindowGroup {
            ContentView(batteryManager: batteryManager, networkSender: networkSender)
                .onAppear {
                    batteryManager.startMonitoring()
                }
                .onChange(of: batteryManager.currentData) { _, newData in
                    if let data = newData {
                        networkSender.send(data)
                    }
                }
        }
    }
}
