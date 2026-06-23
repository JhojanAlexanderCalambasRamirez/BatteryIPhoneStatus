import WidgetKit
import SwiftUI
import BatteryShared

struct MacBatteryEntry: TimelineEntry {
    let date: Date
    let batteryData: BatteryData?
}

struct MacBatteryProvider: TimelineProvider {
    func placeholder(in context: Context) -> MacBatteryEntry {
        MacBatteryEntry(date: .now, batteryData: BatteryData(level: 85, state: .unplugged, deviceName: "MacBook Pro"))
    }

    func getSnapshot(in context: Context, completion: @escaping (MacBatteryEntry) -> Void) {
        let data = SharedStorage.load(forKey: SharedStorage.macBatteryKey, suiteName: SharedStorage.iosSuiteName)
        completion(MacBatteryEntry(date: .now, batteryData: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MacBatteryEntry>) -> Void) {
        let data = SharedStorage.load(forKey: SharedStorage.macBatteryKey, suiteName: SharedStorage.iosSuiteName)
        let entry = MacBatteryEntry(date: .now, batteryData: data)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct MacBatteryWidgetView: View {
    var entry: MacBatteryEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if let data = entry.batteryData {
            switch family {
            case .systemSmall:
                smallWidget(data)
            default:
                mediumWidget(data)
            }
        } else {
            noDataView
        }
    }

    private func smallWidget(_ data: BatteryData) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "laptopcomputer")
                .font(.system(size: 20))
                .foregroundStyle(.blue)

            Text("\(data.level)%")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(colorForLevel(data.level))

            HStack(spacing: 3) {
                if data.state == .charging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.green)
                }
                Text(data.statusText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func mediumWidget(_ data: BatteryData) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 70, height: 70)

                Circle()
                    .trim(from: 0, to: CGFloat(data.level) / 100)
                    .stroke(colorForLevel(data.level), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))

                Text("\(data.level)%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "laptopcomputer")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text(data.deviceName)
                        .font(.headline)
                }

                HStack(spacing: 3) {
                    if data.state == .charging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                    }
                    Text(data.statusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(data.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var noDataView: some View {
        VStack(spacing: 8) {
            Image(systemName: "laptopcomputer.trianglebadge.exclamationmark")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Sin datos")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func colorForLevel(_ level: Int) -> Color {
        switch level {
        case 0...15: return .red
        case 16...30: return .orange
        case 31...60: return .yellow
        case 61...85: return .green
        default: return .mint
        }
    }
}

@main
struct MacBatteryWidget: Widget {
    let kind = "MacBatteryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MacBatteryProvider()) { entry in
            MacBatteryWidgetView(entry: entry)
        }
        .configurationDisplayName("Mac Battery")
        .description("Nivel de bateria de tu Mac")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
