import SwiftUI
import UserNotifications

@main
struct DevicePlaygroundApp: App {
    @StateObject private var settings = AppSettings()
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environment(\.locale, settings.locale)
                .preferredColorScheme(settings.colorScheme)
                .tint(.accentColor)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        NotificationCenter.default.post(name: .didReceiveNotificationAction,
                                        object: nil,
                                        userInfo: ["actionId": response.actionIdentifier,
                                                   "requestId": response.notification.request.identifier])
        completionHandler()
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        NotificationCenter.default.post(name: .didReceiveDeviceToken, object: nil, userInfo: ["token": token])
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationCenter.default.post(name: .didFailRemoteRegistration, object: nil, userInfo: ["error": error.localizedDescription])
    }
}

extension Notification.Name {
    static let didReceiveNotificationAction = Notification.Name("didReceiveNotificationAction")
    static let didReceiveDeviceToken = Notification.Name("didReceiveDeviceToken")
    static let didFailRemoteRegistration = Notification.Name("didFailRemoteRegistration")
}
