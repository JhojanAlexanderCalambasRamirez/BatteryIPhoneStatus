import SwiftUI
import BatteryShared

struct ContentView: View {
    @ObservedObject var batteryManager: BatteryManager
    @ObservedObject var networkSender: NetworkSender

    var body: some View {
        GeometryReader { geo in
            let circleSize = geo.size.width * 0.5

            VStack(spacing: 0) {
                Spacer()

                headerSection

                Spacer()
                    .frame(height: geo.size.height * 0.04)

                if let data = batteryManager.currentData {
                    batteryDisplay(data, size: circleSize)
                } else {
                    ProgressView("Leyendo batería...")
                }

                Spacer()

                connectionStatus
                    .padding(.bottom, 16)

                creditsSection
                    .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? 8 : 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
        }
        .background {
            Color.black.ignoresSafeArea()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "iphone.gen3")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
                .symbolEffect(.pulse, isActive: networkSender.connectionState == .searching)

            Text("Battery Sender")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Enviando datos a Mac")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
    }

    private func batteryDisplay(_ data: BatteryData, size: CGFloat) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 10)
                    .frame(width: size, height: size)

                Circle()
                    .trim(from: 0, to: CGFloat(data.level) / 100)
                    .stroke(
                        colorForCategory(data.colorCategory),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: data.level)

                VStack(spacing: 6) {
                    Image(systemName: batteryIconName(data))
                        .font(.system(size: size * 0.1))
                        .foregroundStyle(colorForCategory(data.colorCategory))

                    Text("\(data.level)%")
                        .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 4) {
                        if data.state == .charging {
                            Image(systemName: "bolt.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                        Text(data.statusText)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }

            Text(data.deviceName)
                .font(.headline)
                .foregroundStyle(.gray)
        }
    }

    private var connectionStatus: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(connectionColor)
                .frame(width: 10, height: 10)

            Text(connectionText)
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.08), in: Capsule())
    }

    private var connectionColor: Color {
        switch networkSender.connectionState {
        case .connected: .green
        case .connecting: .yellow
        case .searching: .orange
        case .disconnected: .red
        }
    }

    private var connectionText: String {
        switch networkSender.connectionState {
        case .connected:
            if let mac = networkSender.macName {
                return "Conectado a \(mac)"
            }
            return "Conectado"
        case .connecting: return "Conectando..."
        case .searching: return "Buscando Mac..."
        case .disconnected: return "Desconectado"
        }
    }

    private var creditsSection: some View {
        VStack(spacing: 6) {
            Text("Dev J4CR")
                .font(.caption.bold())
                .foregroundStyle(.gray)

            HStack(spacing: 16) {
                Link(destination: URL(string: "https://github.com/JhojanAlexanderCalambasRamirez")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                        Text("GitHub")
                    }
                    .font(.caption)
                }

                Link(destination: URL(string: "https://www.linkedin.com/in/j4cr/")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                        Text("LinkedIn")
                    }
                    .font(.caption)
                }
            }
        }
    }

    private func batteryIconName(_ data: BatteryData) -> String {
        if data.state == .charging {
            return "battery.100.bolt"
        }
        switch data.level {
        case 0...25: return "battery.25"
        case 26...50: return "battery.50"
        case 51...75: return "battery.75"
        default: return "battery.100"
        }
    }

    private func colorForCategory(_ cat: ColorCategory) -> Color {
        switch cat {
        case .critical: .red
        case .low: .orange
        case .medium: .yellow
        case .good: .green
        case .full: .mint
        }
    }
}
