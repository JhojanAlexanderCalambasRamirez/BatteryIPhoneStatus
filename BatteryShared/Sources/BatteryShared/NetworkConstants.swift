import Foundation
import Network

public enum BatteryNetwork {
    public static let bonjourType = "_batterymon._tcp"
    public static let bonjourDomain = "local."
    public static let serviceName = "BatteryMonitor"

    public static var nwBonjourType: NWBrowser.Descriptor {
        .bonjour(type: bonjourType, domain: bonjourDomain)
    }

    public static var nwParameters: NWParameters {
        let tcp = NWProtocolTCP.Options()
        tcp.enableKeepalive = true
        tcp.keepaliveInterval = 30
        let params = NWParameters(tls: nil, tcp: tcp)
        params.includePeerToPeer = true
        return params
    }
}
