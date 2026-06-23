import Foundation

public enum SharedStorage {
    public static func save(_ data: BatteryData, forKey key: String, suiteName: String) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let encoded = try? encoder.encode(data) {
            defaults.set(encoded, forKey: key)
        }
    }

    public static func load(forKey key: String, suiteName: String) -> BatteryData? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(BatteryData.self, from: data)
    }

    public static let macBatteryKey = "macBatteryData"
    public static let iphoneBatteryKey = "iphoneBatteryData"
    public static let iosSuiteName = "group.com.j4cr.batterysender"
    public static let macSuiteName = "group.com.j4cr.batterymonitor"
}
