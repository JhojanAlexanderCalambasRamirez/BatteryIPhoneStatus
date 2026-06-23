import Foundation
import Network
import BatteryShared
import UserNotifications

@MainActor
final class BatteryReceiver: ObservableObject {
    @Published var latestData: BatteryData?
    @Published var isListening = false
    @Published var connectedDevice: String?

    private var listener: NWListener?
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "battery.receiver")

    init() {
        requestNotificationPermission()
        startListener()
    }

    func startListener() {
        do {
            let params = BatteryNetwork.nwParameters
            listener = try NWListener(using: params)

            let service = NWListener.Service(
                name: BatteryNetwork.serviceName,
                type: BatteryNetwork.bonjourType
            )
            listener?.service = service

            listener?.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    guard let self else { return }
                    switch state {
                    case .ready:
                        self.isListening = true
                    case .failed:
                        self.isListening = false
                        self.restartListener()
                    default:
                        break
                    }
                }
            }

            listener?.newConnectionHandler = { [weak self] newConn in
                Task { @MainActor in
                    self?.handleConnection(newConn)
                }
            }

            listener?.start(queue: queue)
        } catch {
            print("Listener failed: \(error)")
        }
    }

    private func restartListener() {
        listener?.cancel()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            startListener()
        }
    }

    private func handleConnection(_ conn: NWConnection) {
        connection?.cancel()
        connection = conn

        conn.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                guard let self else { return }
                switch state {
                case .ready:
                    self.connectedDevice = "Conectado"
                    self.startReceiving(on: conn)
                case .failed, .cancelled:
                    self.connectedDevice = nil
                default:
                    break
                }
            }
        }

        conn.start(queue: queue)
    }

    private func startReceiving(on conn: NWConnection) {
        receiveNext(on: conn)
    }

    private nonisolated func receiveNext(on conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] content, _, isComplete, error in
            if let data = content, let self {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if let battery = try? decoder.decode(BatteryData.self, from: data) {
                    Task { @MainActor in
                        self.handleBatteryUpdate(battery)
                    }
                }
            }
            if !isComplete && error == nil {
                self?.receiveNext(on: conn)
            } else {
                Task { @MainActor in
                    self?.connectedDevice = nil
                }
            }
        }
    }

    private func handleBatteryUpdate(_ battery: BatteryData) {
        let previousLevel = latestData?.level
        latestData = battery
        connectedDevice = battery.deviceName

        if let prev = previousLevel, prev > 20 && battery.level <= 20 {
            sendLowBatteryNotification(battery)
        }
        if let prev = previousLevel, prev > 10 && battery.level <= 10 {
            sendCriticalBatteryNotification(battery)
        }
        if let prev = previousLevel, prev < 100 && battery.level == 100 {
            sendFullChargeNotification(battery)
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendLowBatteryNotification(_ data: BatteryData) {
        let content = UNMutableNotificationContent()
        content.title = "Batería Baja — \(data.deviceName)"
        content.body = "Nivel: \(data.level)%"
        content.sound = .default
        let request = UNNotificationRequest(identifier: "lowBattery", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func sendCriticalBatteryNotification(_ data: BatteryData) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Batería Crítica — \(data.deviceName)"
        content.body = "Nivel: \(data.level)%. ¡Conectar cargador!"
        content.sound = .defaultCritical
        let request = UNNotificationRequest(identifier: "criticalBattery", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func sendFullChargeNotification(_ data: BatteryData) {
        let content = UNMutableNotificationContent()
        content.title = "🔋 Carga Completa — \(data.deviceName)"
        content.body = "Batería al 100%. Podés desconectar el cargador."
        content.sound = .default
        let request = UNNotificationRequest(identifier: "fullCharge", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    deinit {
        listener?.cancel()
        connection?.cancel()
    }
}
