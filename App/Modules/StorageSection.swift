import SwiftUI

@MainActor
final class StorageModel: ObservableObject {
    @Published var filesOn = false
    @Published var icloudOn = false
    @Published var cacheOn = false
    @Published var docsOn = false

    @Published var fileText: String = "Hello from Device Playground"
    @Published var loadedText: String = ""
    @Published var icloudAvailable: Bool = false
    @Published var cacheBytes: Int = 0

    private var url: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("sample.txt")
    }

    func write() {
        try? fileText.write(to: url, atomically: true, encoding: .utf8)
    }
    func read() {
        loadedText = (try? String(contentsOf: url)) ?? "—"
    }
    func delete() {
        try? FileManager.default.removeItem(at: url)
        loadedText = ""
    }
    func checkICloud() {
        icloudAvailable = FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil
    }
    func cacheSize() {
        let cache = URLCache.shared
        cacheBytes = cache.currentDiskUsage + cache.currentMemoryUsage
    }
}

struct StorageSection: View {
    @StateObject private var m = StorageModel()

    var body: some View {
        VStack(spacing: 16) {
            FeatureCard(titleKey: "sto_files", symbol: "doc.fill", tint: .orange, isOn: $m.filesOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("sto_files_desc").font(.callout).foregroundStyle(.secondary)
                    TextField("text", text: $m.fileText).textFieldStyle(.roundedBorder)
                    HStack {
                        ActionButton(titleKey: "sto_write", systemImage: "square.and.arrow.down", tint: .orange) { m.write() }
                        ActionButton(titleKey: "sto_read", systemImage: "square.and.arrow.up", tint: .orange) { m.read() }
                        ActionButton(titleKey: "sto_delete", systemImage: "trash", tint: .red) { m.delete() }
                    }
                    if !m.loadedText.isEmpty {
                        Text(m.loadedText).font(.callout.monospaced()).textSelection(.enabled)
                    }
                }
            }
            FeatureCard(titleKey: "sto_icloud", symbol: "icloud.fill", tint: .orange, isOn: $m.icloudOn,
                        onChange: { on in if on { m.checkICloud() } }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("sto_icloud_desc").font(.callout).foregroundStyle(.secondary)
                    StatusPill(textKey: m.icloudAvailable ? "granted" : "not_available",
                               systemImage: m.icloudAvailable ? "checkmark.icloud.fill" : "xmark.icloud.fill",
                               tint: m.icloudAvailable ? .green : .red)
                    Text("requires_paid_dev_account").font(.caption).foregroundStyle(.orange)
                }
            }
            FeatureCard(titleKey: "sto_cache", symbol: "tray.full.fill", tint: .orange, isOn: $m.cacheOn,
                        onChange: { on in if on { m.cacheSize() } }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("sto_cache_desc").font(.callout).foregroundStyle(.secondary)
                    HStack { Text("size").font(.callout.weight(.semibold)); Spacer(); Text(ByteCountFormatter.string(fromByteCount: Int64(m.cacheBytes), countStyle: .file)).font(.callout.monospaced()) }
                    ActionButton(titleKey: "trigger", systemImage: "arrow.clockwise", tint: .orange) { m.cacheSize() }
                }
            }
            FeatureCard(titleKey: "sto_documents", symbol: "folder.fill", tint: .orange, isOn: $m.docsOn) {
                Text("sto_documents_desc").font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}
