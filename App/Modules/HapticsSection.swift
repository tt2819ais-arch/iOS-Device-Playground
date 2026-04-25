import SwiftUI
import UIKit
import CoreHaptics
import AudioToolbox

@MainActor
final class HapticsModel: ObservableObject {
    @Published var basicOn = false
    @Published var impactOn = false
    @Published var notifOn = false
    @Published var selectionOn = false
    @Published var customOn = false

    private var engine: CHHapticEngine?

    func basic() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let gen = UIImpactFeedbackGenerator(style: style); gen.prepare(); gen.impactOccurred()
    }
    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let gen = UINotificationFeedbackGenerator(); gen.prepare(); gen.notificationOccurred(type)
    }
    func selection() {
        let gen = UISelectionFeedbackGenerator(); gen.prepare(); gen.selectionChanged()
    }

    func custom() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            basic(); return
        }
        do {
            if engine == nil {
                engine = try CHHapticEngine()
                try engine?.start()
            }
            let rising = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2),
                ],
                relativeTime: 0,
                duration: 0.6
            )
            let tap = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0),
                ],
                relativeTime: 0.65
            )
            let pattern = try CHHapticPattern(events: [rising, tap], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            basic()
        }
    }
}

struct HapticsSection: View {
    @StateObject private var m = HapticsModel()

    var body: some View {
        VStack(spacing: 16) {
            FeatureCard(titleKey: "haptic_vibration", symbol: "iphone.radiowaves.left.and.right", tint: .purple, isOn: $m.basicOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("haptic_vibration_desc").font(.callout).foregroundStyle(.secondary)
                    ActionButton(titleKey: "haptic_play", systemImage: "play.fill", tint: .purple) { m.basic() }
                }
            }

            FeatureCard(titleKey: "haptic_impact", symbol: "hand.tap.fill", tint: .purple, isOn: $m.impactOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("haptic_impact_desc").font(.callout).foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ActionButton(titleKey: "haptic_light", tint: .purple) { m.impact(.light) }
                            ActionButton(titleKey: "haptic_medium", tint: .purple) { m.impact(.medium) }
                            ActionButton(titleKey: "haptic_heavy", tint: .purple) { m.impact(.heavy) }
                            ActionButton(titleKey: "haptic_soft", tint: .purple) { m.impact(.soft) }
                            ActionButton(titleKey: "haptic_rigid", tint: .purple) { m.impact(.rigid) }
                        }
                    }
                }
            }

            FeatureCard(titleKey: "haptic_notification", symbol: "checkmark.seal.fill", tint: .purple, isOn: $m.notifOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("haptic_notification_desc").font(.callout).foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        ActionButton(titleKey: "haptic_success", tint: .green) { m.notify(.success) }
                        ActionButton(titleKey: "haptic_warning", tint: .orange) { m.notify(.warning) }
                        ActionButton(titleKey: "haptic_error", tint: .red) { m.notify(.error) }
                    }
                }
            }

            FeatureCard(titleKey: "haptic_selection", symbol: "slider.horizontal.below.rectangle", tint: .purple, isOn: $m.selectionOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("haptic_selection_desc").font(.callout).foregroundStyle(.secondary)
                    ActionButton(titleKey: "haptic_play", systemImage: "play.fill", tint: .purple) { m.selection() }
                }
            }

            FeatureCard(titleKey: "haptic_custom", symbol: "waveform.path.ecg.rectangle.fill", tint: .purple, isOn: $m.customOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("haptic_custom_desc").font(.callout).foregroundStyle(.secondary)
                    ActionButton(titleKey: "haptic_play", systemImage: "sparkles", tint: .purple) { m.custom() }
                }
            }
        }
    }
}
