import Foundation

public struct BatteryData: Codable, Sendable, Equatable {
    public let level: Int
    public let state: BatteryState
    public let deviceName: String
    public let timestamp: Date

    public init(level: Int, state: BatteryState, deviceName: String, timestamp: Date = Date()) {
        self.level = level
        self.state = state
        self.deviceName = deviceName
        self.timestamp = timestamp
    }

    public var statusText: String {
        switch level {
        case 0...15: return "Crítico"
        case 16...30: return "Bajo"
        case 31...60: return "Medio"
        case 61...85: return "Bueno"
        default: return "Excelente"
        }
    }

    public var colorCategory: ColorCategory {
        switch level {
        case 0...15: return .critical
        case 16...30: return .low
        case 31...60: return .medium
        case 61...85: return .good
        default: return .full
        }
    }
}

public enum BatteryState: String, Codable, Sendable {
    case unknown
    case unplugged
    case charging
    case full
}

public enum ColorCategory: Sendable {
    case critical, low, medium, good, full
}
