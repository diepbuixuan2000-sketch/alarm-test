import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        LogManager.shared.log("Ứng dụng khởi động (didFinishLaunching)", level: .info)
        return true
    }
}

@main
struct AlarmTestAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                LogManager.shared.log("Trạng thái: ACTIVE (Màn hình mở, đang dùng)", level: .info)
            case .inactive:
                LogManager.shared.log("Trạng thái: INACTIVE (Đang chuyển đổi / Bảng thông báo kéo xuống)", level: .warning)
            case .background:
                LogManager.shared.log("Trạng thái: BACKGROUND (Đã khoá máy hoặc thu nhỏ ứng dụng)", level: .warning)
            @unknown default:
                break
            }
        }
    }
}
