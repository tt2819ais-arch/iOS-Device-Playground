import SwiftUI
import UserNotifications
import UIKit

@MainActor
final class NotificationsModel: ObservableObject {
    @Published var localOn = false
    @Published var pushOn = false
    @Published var actionsOn = false
    @Published var badgeOn = false

    @Published var authStatus: UNAuthorizationStatus = .notDetermined
    @Published var lastError: String?
    @Published var deviceToken: String?
    @Published var lastAction: String?
    @Published var badgeCount: Int = 0

    private let center = UNUserNotificationCenter.current()

    init() {
        Task { await refreshStatus() }
        NotificationCenter.default.addObserver(forName: .didReceiveDeviceToken, object: nil, queue: .main) { [weak self] note in
            self?.deviceToken = note.userInfo?["token"] as? String
        }
        NotificationCenter.default.addObserver(forName: .didFailRemoteRegistration, object: nil, queue: .main) { [weak self] note in
            self?.lastError = note.userInfo?["error"] as? String
        }
        NotificationCenter.default.addObserver(forName: .didReceiveNotificationAction, object: nil, queue: .main) { [weak self] note in
            self?.lastAction = note.userInfo?["actionId"] as? String
        }
    }

    func refreshStatus() async {
        let s = await center.notificationSettings()
        await MainActor.run { self.authStatus = s.authorizationStatus }
    }

    func requestPermission() async {
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge, .provisional])
            await refreshStatus()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func scheduleLocal() async {
        await ensurePermission()
        let content = UNMutableNotificationContent()
        content.title = "Device Playground"
        content.body = "Это локальное уведомление / This is a local notification"
        content.sound = .default
        content.badge = NSNumber(value: badgeCount + 1)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func scheduleWithActions() async {
        await ensurePermission()
        let accept = UNNotificationAction(identifier: "ACCEPT", title: "Accept", options: [.foreground])
        let dismiss = UNNotificationAction(identifier: "DISMISS", title: "Dismiss", options: [.destructive])
        let category = UNNotificationCategory(identifier: "DP_ACTIONS", actions: [accept, dismiss], intentIdentifiers: [], options: [])
        center.setNotificationCategories([category])

        let content = UNMutableNotificationContent()
        content.title = "Action notification"
        content.body = "Tap an action button"
        content.sound = .default
        content.categoryIdentifier = "DP_ACTIONS"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func registerForRemote() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func bumpBadge() async {
        badgeCount += 1
        try? await center.setBadgeCount(badgeCount)
    }

    func clearBadge() async {
        badgeCount = 0
        try? await center.setBadgeCount(0)
    }

    private func ensurePermission() async {
        await refreshStatus()
        if authStatus == .notDetermined {
            await requestPermission()
        }
    }

    var statusKey: LocalizedStringKey {
        switch authStatus {
        case .authorized:    return "notif_status_authorized"
        case .denied:        return "notif_status_denied"
        case .provisional:   return "notif_status_provisional"
        case .ephemeral:     return "notif_status_authorized"
        case .notDetermined: return "unknown"
        @unknown default:    return "unknown"
        }
    }

    var statusTint: Color {
        switch authStatus {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return .red
        default: return .secondary.opacity(1)
        }
    }
}

struct NotificationsSection: View {
    @StateObject private var m = NotificationsModel()

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                StatusPill(textKey: m.statusKey, systemImage: "bell.fill", tint: m.statusTint)
                Spacer()
                Button {
                    Task { await m.requestPermission() }
                } label: {
                    Label("notif_request_permission", systemImage: "lock.open.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            FeatureCard(titleKey: "notif_local", symbol: "bell.fill", tint: .red, isOn: $m.localOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("notif_local_desc").font(.callout).foregroundStyle(.secondary)
                    ActionButton(titleKey: "notif_send_test", systemImage: "paperplane.fill", tint: .red) {
                        Task { await m.scheduleLocal() }
                    }
                }
            }

            FeatureCard(titleKey: "notif_push", symbol: "antenna.radiowaves.left.and.right", tint: .red, isOn: $m.pushOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("notif_push_desc").font(.callout).foregroundStyle(.secondary)
                    Text("requires_paid_dev_account").font(.caption).foregroundStyle(.orange)
                    ActionButton(titleKey: "notif_register", systemImage: "antenna.radiowaves.left.and.right.circle.fill", tint: .red) {
                        m.registerForRemote()
                    }
                    if let token = m.deviceToken {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("notif_token").font(.caption.weight(.semibold))
                            Text(token).font(.caption.monospaced()).textSelection(.enabled).lineLimit(3)
                        }
                    }
                    if let err = m.lastError {
                        Text(err).font(.caption).foregroundStyle(.red)
                    }
                }
            }

            FeatureCard(titleKey: "notif_actions", symbol: "hand.tap.fill", tint: .red, isOn: $m.actionsOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("notif_actions_desc").font(.callout).foregroundStyle(.secondary)
                    ActionButton(titleKey: "notif_show_actions", systemImage: "rectangle.stack.fill", tint: .red) {
                        Task { await m.scheduleWithActions() }
                    }
                    if let last = m.lastAction {
                        Text("notif_last_action").font(.caption.weight(.semibold))
                        Text(last).font(.caption.monospaced())
                    }
                }
            }

            FeatureCard(titleKey: "notif_badge", symbol: "1.circle.fill", tint: .red, isOn: $m.badgeOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("notif_badge_desc").font(.callout).foregroundStyle(.secondary)
                    HStack {
                        ActionButton(titleKey: "trigger", systemImage: "plus.circle.fill", tint: .red) {
                            Task { await m.bumpBadge() }
                        }
                        ActionButton(titleKey: "notif_clear_badge", systemImage: "minus.circle.fill", tint: .red) {
                            Task { await m.clearBadge() }
                        }
                    }
                }
            }
        }
    }
}
