import SwiftUI
import CoreSpotlight
import UniformTypeIdentifiers
import AppIntents

struct SystemIntegrationsSection: View {
    @State private var siriOn = false
    @State private var spotlightOn = false
    @State private var widgetsOn = false
    @State private var lastResult = ""

    var body: some View {
        VStack(spacing: 16) {
            FeatureCard(titleKey: "sys_siri", symbol: "mic.circle.fill", tint: .yellow, isOn: $siriOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("sys_siri_desc").font(.callout).foregroundStyle(.secondary)
                    ActionButton(titleKey: "sys_donate", systemImage: "sparkles", tint: .yellow) {
                        Task {
                            do {
                                try await GreetIntent().donate()
                                lastResult = "donated"
                            } catch {
                                lastResult = error.localizedDescription
                            }
                        }
                    }
                    if !lastResult.isEmpty { Text(lastResult).font(.caption.monospaced()) }
                }
            }
            FeatureCard(titleKey: "sys_spotlight", symbol: "magnifyingglass.circle.fill", tint: .yellow, isOn: $spotlightOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("sys_spotlight_desc").font(.callout).foregroundStyle(.secondary)
                    ActionButton(titleKey: "sys_index", systemImage: "magnifyingglass", tint: .yellow) {
                        let attr = CSSearchableItemAttributeSet(contentType: UTType.text)
                        attr.title = "Device Playground"
                        attr.contentDescription = "Test all iOS device features"
                        let item = CSSearchableItem(uniqueIdentifier: "dp.app", domainIdentifier: "dp", attributeSet: attr)
                        CSSearchableIndex.default().indexSearchableItems([item]) { err in
                            DispatchQueue.main.async {
                                lastResult = err?.localizedDescription ?? "indexed"
                            }
                        }
                    }
                    Text("sys_search_in_spotlight").font(.caption).foregroundStyle(.secondary)
                }
            }
            FeatureCard(titleKey: "sys_widgets", symbol: "rectangle.3.group.fill", tint: .yellow, isOn: $widgetsOn) {
                Text("sys_widgets_desc").font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}

struct GreetIntent: AppIntent {
    static var title: LocalizedStringResource = "Greet from Device Playground"
    static var description = IntentDescription("Just a sample app intent that returns a greeting.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        return .result(value: "Hello from Device Playground!")
    }
}
