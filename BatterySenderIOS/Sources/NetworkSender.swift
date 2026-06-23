import Foundation
import Network
import BatteryShared

@MainActor
final class NetworkSender: ObservableObject {
    @Published var connectionState: ConnectionState = .searching
    @Published var macName: String?

    private var browser: NWBrowser?
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "battery.sender")

    enum ConnectionState: Equatable {
        case searching
        case connecting
        case connected
        case disconnected
    }

    init() {
        startBrowsing()
    }

    func startBrowsing() {
        connectionState = .searching

        browser = NWBrowser(for: BatteryNetwork.nwBonjourType, using: BatteryNetwork.nwParameters)

        browser?.browseResultsChangedHandler = { [weak self] results, _ in
            guard let result = results.first else { return }
            Task { @MainActor in
                self?.connectTo(result)
            }
        }

        browser?.stateUpdateHandler = { [weak self] state in
            if case .failed = state {
                Task { @MainActor in
                    self?.restartBrowsing()
                }
            }
        }

        browser?.start(queue: queue)
    }

    private func connectTo(_ result: NWBrowser.Result) {
        connection?.cancel()
        connectionState = .connecting

        let endpoint = result.endpoint
        if case .service(let name, _, _, _) = endpoint {
            macName = name
        }

        let conn = NWConnection(to: endpoint, using: BatteryNetwork.nwParameters)

        conn.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    self?.connectionState = .connected
                case .failed, .cancelled:
                    self?.connectionState = .disconnected
                    self?.reconnect()
                default:
                    break
                }
            }
        }

        connection = conn
        conn.start(queue: queue)
    }

    private func reconnect() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            startBrowsing()
        }
    }

    private func restartBrowsing() {
        browser?.cancel()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            startBrowsing()
        }
    }

    func send(_ data: BatteryData) {
        guard connectionState == .connected, let conn = connection else { return }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let jsonData = try? encoder.encode(data) else { return }

        conn.send(content: jsonData, completion: .contentProcessed { [weak self] error in
            if error != nil {
                Task { @MainActor in
                    self?.connectionState = .disconnected
                    self?.reconnect()
                }
            }
        })
    }

    deinit {
        browser?.cancel()
        connection?.cancel()
    }
}
