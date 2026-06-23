import SwiftUI
import BatteryShared

struct MenuBarView: View {
    @ObservedObject var receiver: BatteryReceiver

    var body: some View {
        VStack(spacing: 0) {
            if let data = receiver.latestData {
                batteryContent(data)
            } else {
                waitingContent
            }

            Divider()
                .padding(.vertical, 8)

            statusFooter

            creditsSection

            Button("Salir") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            .padding(.top, 8)
        }
        .padding(16)
        .frame(width: 280)
    }

    private func batteryContent(_ data: BatteryData) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "iphone.gen3")
                    .foregroundStyle(.blue)
                Text(data.deviceName)
                    .font(.headline)
                Spacer()
                stateLabel(data.state)
            }

            BatteryGauge(level: data.level, category: data.colorCategory)
                .frame(height: 32)

            HStack {
                Text("\(data.level)%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(colorForCategory(data.colorCategory))
                Spacer()
                VStack(alignment: .trailing) {
                    Text(data.statusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(data.timestamp, style: .time)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var waitingContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Esperando iPhone...")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Asegúrate de que ambos dispositivos\nestén en la misma red WiFi")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }

    private var statusFooter: some View {
        HStack {
            Circle()
                .fill(receiver.isListening ? .green : .red)
                .frame(width: 8, height: 8)
            Text(receiver.isListening ? "Escuchando" : "Desconectado")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if let device = receiver.connectedDevice {
                Text(device)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func stateLabel(_ state: BatteryState) -> some View {
        switch state {
        case .charging:
            Label("Cargando", systemImage: "bolt.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .full:
            Label("Completa", systemImage: "bolt.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .unplugged:
            Label("Batería", systemImage: "battery.100")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .unknown:
            EmptyView()
        }
    }

    private var creditsSection: some View {
        VStack(spacing: 6) {
            Divider()
                .padding(.vertical, 4)

            Text("Dev J4CR")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Link(destination: URL(string: "https://github.com/JhojanAlexanderCalambasRamirez")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                        Text("GitHub")
                    }
                    .font(.caption2)
                }

                Link(destination: URL(string: "https://www.linkedin.com/in/j4cr/")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                        Text("LinkedIn")
                    }
                    .font(.caption2)
                }
            }
        }
    }

    private func colorForCategory(_ cat: ColorCategory) -> Color {
        switch cat {
        case .critical: return .red
        case .low: return .orange
        case .medium: return .yellow
        case .good: return .green
        case .full: return .mint
        }
    }
}

struct BatteryGauge: View {
    let level: Int
    let category: ColorCategory

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary)

                RoundedRectangle(cornerRadius: 6)
                    .fill(gradientForCategory(category))
                    .frame(width: geo.size.width * CGFloat(level) / 100)
                    .animation(.easeInOut(duration: 0.5), value: level)
            }
        }
    }

    private func gradientForCategory(_ cat: ColorCategory) -> LinearGradient {
        switch cat {
        case .critical:
            return LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
        case .low:
            return LinearGradient(colors: [.orange, .orange.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
        case .medium:
            return LinearGradient(colors: [.yellow, .yellow.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
        case .good:
            return LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
        case .full:
            return LinearGradient(colors: [.mint, .green], startPoint: .leading, endPoint: .trailing)
        }
    }
}
