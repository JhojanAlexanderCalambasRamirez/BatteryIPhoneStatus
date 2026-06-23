import UIKit
import BatteryShared
import UserNotifications

@MainActor
final class BatteryManager: ObservableObject {
    @Published var currentData: BatteryData?

    private var timer: Timer?
    private var previousLevel: Int?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    func startMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        requestNotificationPermission()

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

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.updateBattery()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.beginBackgroundWork()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateBattery()
            }
        }
    }

    private func updateBattery() {
        let device = UIDevice.current
        let rawLevel = device.batteryLevel
        let level = rawLevel < 0 ? 0 : Int(roundf(rawLevel * 100))

        let state: BatteryState = switch device.batteryState {
        case .charging: .charging
        case .full: .full
        case .unplugged: .unplugged
        default: .unknown
        }

        if let prev = previousLevel, prev < 100 && (level == 100 || state == .full) {
            sendFullChargeNotification()
        }
        if let prev = previousLevel, prev > 20 && level <= 20 {
            sendLowBatteryNotification(level)
        }
        if let prev = previousLevel, prev > 10 && level <= 10 {
            sendCriticalBatteryNotification(level)
        }

        previousLevel = level

        currentData = BatteryData(
            level: level,
            state: state,
            deviceName: device.name
        )
    }

    private func beginBackgroundWork() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundWork()
        }
    }

    private func endBackgroundWork() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func sendFullChargeNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Carga Completa"
        content.body = "Tu iPhone esta al 100%. Podes desconectar el cargador."
        content.sound = .default
        let request = UNNotificationRequest(identifier: "fullCharge", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func sendLowBatteryNotification(_ level: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Bateria Baja"
        content.body = "Tu iPhone esta al \(level)%."
        content.sound = .default
        let request = UNNotificationRequest(identifier: "lowBattery", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func sendCriticalBatteryNotification(_ level: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Bateria Critica"
        content.body = "Tu iPhone esta al \(level)%. Conecta el cargador!"
        content.sound = .defaultCritical
        let request = UNNotificationRequest(identifier: "criticalBattery", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        UIDevice.current.isBatteryMonitoringEnabled = false
        endBackgroundWork()
    }
}
