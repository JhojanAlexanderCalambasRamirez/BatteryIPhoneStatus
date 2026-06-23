import SwiftUI
import BackgroundTasks

@main
struct BatterySenderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var batteryManager = BatteryManager()
    @StateObject private var networkSender = NetworkSender()

    var body: some Scene {
        WindowGroup {
            ContentView(batteryManager: batteryManager, networkSender: networkSender)
                .onAppear {
                    batteryManager.startMonitoring()
                    appDelegate.batteryManager = batteryManager
                    appDelegate.networkSender = networkSender
                }
                .onChange(of: batteryManager.currentData) { _, newData in
                    if let data = newData {
                        networkSender.send(data)
                    }
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    var batteryManager: BatteryManager?
    var networkSender: NetworkSender?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.j4cr.BatterySenderIOS.refresh",
            using: nil
        ) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleBackgroundRefresh()
    }

    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.j4cr.BatterySenderIOS.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        scheduleBackgroundRefresh()

        Task { @MainActor in
            if let manager = self.batteryManager, let sender = self.networkSender {
                manager.startMonitoring()
                if let data = manager.currentData {
                    sender.send(data)
                }
            }
            task.setTaskCompleted(success: true)
        }
    }
}
