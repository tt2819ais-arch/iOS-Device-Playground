import SwiftUI
import CoreNFC

struct ExtrasSection: View {
    @State private var carplayOn = false
    @State private var homekitOn = false
    @State private var airdropOn = false
    @State private var nfcOn = false
    @State private var showShare = false
    @State private var nfcStatus = "—"
    @State private var nfcDelegate: NFCSessionHolder?

    var body: some View {
        VStack(spacing: 16) {
            FeatureCard(titleKey: "ex_carplay", symbol: "car.fill", tint: .accentColor, isOn: $carplayOn) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ex_carplay_desc").font(.callout).foregroundStyle(.secondary)
                    Text("requires_paid_dev_account").font(.caption).foregroundStyle(.orange)
                }
            }
            FeatureCard(titleKey: "ex_homekit", symbol: "house.fill", tint: .accentColor, isOn: $homekitOn) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ex_homekit_desc").font(.callout).foregroundStyle(.secondary)
                    Text("requires_paid_dev_account").font(.caption).foregroundStyle(.orange)
                }
            }
            FeatureCard(titleKey: "ex_airdrop", symbol: "airdropicon", tint: .accentColor, isOn: $airdropOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ex_airdrop_desc").font(.callout).foregroundStyle(.secondary)
                    ActionButton(titleKey: "ex_share_for_airdrop", systemImage: "paperplane.fill") { showShare = true }
                }
            }
            .sheet(isPresented: $showShare) {
                ShareSheet(items: ["Try Device Playground via AirDrop", URL(string: "https://github.com/tt2819ais-arch/iOS-Device-Playground")!])
            }
            FeatureCard(titleKey: "ex_nfc", symbol: "wave.3.right.circle.fill", tint: .accentColor, isOn: $nfcOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ex_nfc_desc").font(.callout).foregroundStyle(.secondary)
                    Text("requires_paid_dev_account").font(.caption).foregroundStyle(.orange)
                    ActionButton(titleKey: "ex_start_nfc", systemImage: "wave.3.right.circle.fill") {
                        startNFC()
                    }
                    Text(nfcStatus).font(.caption.monospaced())
                }
            }
        }
    }

    private func startNFC() {
        guard NFCNDEFReaderSession.readingAvailable else { nfcStatus = "unavailable"; return }
        let holder = NFCSessionHolder { msg in
            nfcStatus = msg
        }
        let session = NFCNDEFReaderSession(delegate: holder, queue: nil, invalidateAfterFirstRead: true)
        session.alertMessage = "Hold your iPhone near an NFC tag"
        session.begin()
        nfcDelegate = holder
    }
}

final class NFCSessionHolder: NSObject, NFCNDEFReaderSessionDelegate {
    let onResult: (String) -> Void
    init(onResult: @escaping (String) -> Void) { self.onResult = onResult }
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        let summary = messages.flatMap { $0.records }.map { $0.payload.count }.map(String.init).joined(separator: ", ")
        DispatchQueue.main.async { self.onResult("payload bytes: \(summary)") }
    }
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async { self.onResult(error.localizedDescription) }
    }
}
