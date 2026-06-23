import SwiftUI

@main
struct BatteryMonitorApp: App {
    @StateObject private var receiver = BatteryReceiver()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(receiver: receiver)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: batteryIcon)
                if let data = receiver.latestData {
                    Text("\(data.level)%")
                }
            }
        }
        .menuBarExtraStyle(.window)
    }

    private var batteryIcon: String {
        guard let data = receiver.latestData else { return "battery.0" }
        switch data.level {
        case 0...12: return "battery.0"
        case 13...37: return "battery.25"
        case 38...62: return "battery.50"
        case 63...87: return "battery.75"
        default: return "battery.100"
        }
    }
}
