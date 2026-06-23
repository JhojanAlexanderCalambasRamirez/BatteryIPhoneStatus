import Foundation
import IOKit.ps
import BatteryShared

final class MacBatteryManager {
    static func getCurrentData() -> BatteryData? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any]
        else { return nil }

        let level = desc[kIOPSCurrentCapacityKey as String] as? Int ?? 0
        let isCharging = desc[kIOPSIsChargingKey as String] as? Bool ?? false
        let maxCapacity = desc[kIOPSMaxCapacityKey as String] as? Int ?? 100

        let state: BatteryState
        if isCharging {
            state = level >= maxCapacity ? .full : .charging
        } else {
            state = .unplugged
        }

        let name = Host.current().localizedName ?? "Mac"

        return BatteryData(
            level: level,
            state: state,
            deviceName: name
        )
    }
}
