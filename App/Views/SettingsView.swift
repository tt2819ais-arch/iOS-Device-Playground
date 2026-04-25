import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("settings_appearance") {
                    Picker(selection: Binding(
                        get: { settings.theme },
                        set: { settings.theme = $0 }
                    )) {
                        ForEach(AppTheme.allCases) { t in
                            Label(t.titleKey, systemImage: t.symbol).tag(t)
                        }
                    } label: {
                        Label("settings_theme", systemImage: "paintpalette.fill")
                    }
                    .pickerStyle(.menu)
                }

                Section("settings_language") {
                    Picker(selection: Binding(
                        get: { settings.language },
                        set: { settings.language = $0 }
                    )) {
                        ForEach(AppLanguage.allCases) { l in
                            HStack {
                                Text(l.flag)
                                Text(l.titleKey)
                            }.tag(l)
                        }
                    } label: {
                        Label("settings_language", systemImage: "globe")
                    }
                    .pickerStyle(.menu)
                }

                Section("settings_about") {
                    LabeledContent("settings_version", value: appVersion)
                    LabeledContent("settings_build", value: appBuild)
                    Link(destination: URL(string: "https://github.com/tt2819ais-arch/iOS-Device-Playground")!) {
                        Label("settings_source", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }
            .navigationTitle("settings_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}
