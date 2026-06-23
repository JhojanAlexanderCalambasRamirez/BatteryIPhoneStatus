import UIKit
import BatteryShared
import Combine

@MainActor
final class BatteryManager: ObservableObject {
    @Published var currentData: BatteryData?

    private var timer: Timer?

    func startMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true

        updateBattery()

        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.updateBattery()
        }

        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.updateBattery()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateBattery()
            }
        }
    }

    private func updateBattery() {
        let device = UIDevice.current
        let level = Int(device.batteryLevel * 100)
        let state: BatteryState = switch device.batteryState {
        case .charging: .charging
        case .full: .full
        case .unplugged: .unplugged
        default: .unknown
        }

        currentData = BatteryData(
            level: max(0, level),
            state: state,
            deviceName: device.name
        )
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        UIDevice.current.isBatteryMonitoringEnabled = false
    }
}
