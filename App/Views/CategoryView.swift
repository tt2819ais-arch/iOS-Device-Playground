import SwiftUI

enum FeatureCategory: String, CaseIterable, Identifiable, Hashable {
    case notifications, haptics, audio, camera, location, sensors, health, biometry,
         network, storage, systemIntegrations, communication, graphics, background, payments, extras

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .notifications:        return "cat_notifications"
        case .haptics:              return "cat_haptics"
        case .audio:                return "cat_audio"
        case .camera:               return "cat_camera"
        case .location:             return "cat_location"
        case .sensors:              return "cat_sensors"
        case .health:               return "cat_health"
        case .biometry:             return "cat_biometry"
        case .network:              return "cat_network"
        case .storage:              return "cat_storage"
        case .systemIntegrations:   return "cat_system"
        case .communication:        return "cat_communication"
        case .graphics:             return "cat_graphics"
        case .background:           return "cat_background"
        case .payments:             return "cat_payments"
        case .extras:               return "cat_extras"
        }
    }

    var subtitleKey: LocalizedStringKey {
        switch self {
        case .notifications:        return "cat_notifications_sub"
        case .haptics:              return "cat_haptics_sub"
        case .audio:                return "cat_audio_sub"
        case .camera:               return "cat_camera_sub"
        case .location:             return "cat_location_sub"
        case .sensors:              return "cat_sensors_sub"
        case .health:               return "cat_health_sub"
        case .biometry:             return "cat_biometry_sub"
        case .network:              return "cat_network_sub"
        case .storage:              return "cat_storage_sub"
        case .systemIntegrations:   return "cat_system_sub"
        case .communication:        return "cat_communication_sub"
        case .graphics:             return "cat_graphics_sub"
        case .background:           return "cat_background_sub"
        case .payments:             return "cat_payments_sub"
        case .extras:               return "cat_extras_sub"
        }
    }

    var symbol: String {
        switch self {
        case .notifications:        return "bell.badge.fill"
        case .haptics:              return "iphone.radiowaves.left.and.right"
        case .audio:                return "speaker.wave.3.fill"
        case .camera:               return "camera.fill"
        case .location:             return "location.fill"
        case .sensors:              return "gyroscope"
        case .health:               return "heart.fill"
        case .biometry:             return "faceid"
        case .network:              return "wifi"
        case .storage:              return "folder.fill"
        case .systemIntegrations:   return "sparkles.square.filled.on.square"
        case .communication:        return "phone.fill"
        case .graphics:             return "paintbrush.pointed.fill"
        case .background:           return "clock.arrow.2.circlepath"
        case .payments:             return "creditcard.fill"
        case .extras:               return "ellipsis.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .notifications:        return .red
        case .haptics:              return .purple
        case .audio:                return .indigo
        case .camera:               return .blue
        case .location:             return .green
        case .sensors:              return .teal
        case .health:               return .pink
        case .biometry:             return .mint
        case .network:              return .cyan
        case .storage:              return .orange
        case .systemIntegrations:   return .yellow
        case .communication:        return .brown
        case .graphics:             return .purple
        case .background:           return .gray
        case .payments:             return .green
        case .extras:               return .accentColor
        }
    }
}

struct CategoryView: View {
    let category: FeatureCategory

    var body: some View {
        ZStack {
            AdaptiveBackground()
            ScrollView {
                VStack(spacing: 16) {
                    sections
                }
                .padding(16)
            }
        }
        .navigationTitle(category.titleKey)
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private var sections: some View {
        switch category {
        case .notifications:        NotificationsSection()
        case .haptics:              HapticsSection()
        case .audio:                AudioSection()
        case .camera:               CameraSection()
        case .location:             LocationSection()
        case .sensors:              SensorsSection()
        case .health:               HealthSection()
        case .biometry:             BiometrySection()
        case .network:              NetworkSection()
        case .storage:              StorageSection()
        case .systemIntegrations:   SystemIntegrationsSection()
        case .communication:        CommunicationSection()
        case .graphics:             GraphicsSection()
        case .background:           BackgroundSection()
        case .payments:             PaymentsSection()
        case .extras:               ExtrasSection()
        }
    }
}
