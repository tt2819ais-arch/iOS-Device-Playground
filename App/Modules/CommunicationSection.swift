import SwiftUI
import UIKit

struct CommunicationSection: View {
    @State private var callOn = false
    @State private var smsOn = false
    @State private var emailOn = false
    @State private var safariOn = false
    @State private var shareOn = false
    @State private var phone = "+15555555555"
    @State private var email = "test@example.com"
    @State private var url = "https://apple.com"
    @State private var smsText = "Hello from Device Playground"
    @State private var showShare = false

    var body: some View {
        VStack(spacing: 16) {
            FeatureCard(titleKey: "com_call", symbol: "phone.fill", tint: .brown, isOn: $callOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("com_call_desc").font(.callout).foregroundStyle(.secondary)
                    TextField("phone", text: $phone).textFieldStyle(.roundedBorder).keyboardType(.phonePad)
                    ActionButton(titleKey: "com_dial", systemImage: "phone.fill", tint: .brown) {
                        if let u = URL(string: "tel://\(phone.filter("+0123456789".contains))") {
                            UIApplication.shared.open(u)
                        }
                    }
                }
            }
            FeatureCard(titleKey: "com_sms", symbol: "message.fill", tint: .brown, isOn: $smsOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("com_sms_desc").font(.callout).foregroundStyle(.secondary)
                    TextField("phone", text: $phone).textFieldStyle(.roundedBorder).keyboardType(.phonePad)
                    TextField("text", text: $smsText).textFieldStyle(.roundedBorder)
                    ActionButton(titleKey: "com_compose", systemImage: "square.and.pencil", tint: .brown) {
                        let body = smsText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let u = URL(string: "sms:\(phone)&body=\(body)") {
                            UIApplication.shared.open(u)
                        }
                    }
                }
            }
            FeatureCard(titleKey: "com_email", symbol: "envelope.fill", tint: .brown, isOn: $emailOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("com_email_desc").font(.callout).foregroundStyle(.secondary)
                    TextField("email", text: $email).textFieldStyle(.roundedBorder).keyboardType(.emailAddress)
                    ActionButton(titleKey: "com_compose", systemImage: "envelope.fill", tint: .brown) {
                        let subject = "Hello".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        let body = "From Device Playground".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let u = URL(string: "mailto:\(email)?subject=\(subject)&body=\(body)") {
                            UIApplication.shared.open(u)
                        }
                    }
                }
            }
            FeatureCard(titleKey: "com_safari", symbol: "safari.fill", tint: .brown, isOn: $safariOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("com_safari_desc").font(.callout).foregroundStyle(.secondary)
                    TextField("url", text: $url).textFieldStyle(.roundedBorder).keyboardType(.URL).autocorrectionDisabled()
                    ActionButton(titleKey: "open", systemImage: "safari.fill", tint: .brown) {
                        if let u = URL(string: url) { UIApplication.shared.open(u) }
                    }
                }
            }
            FeatureCard(titleKey: "com_share", symbol: "square.and.arrow.up", tint: .brown, isOn: $shareOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("com_share_desc").font(.callout).foregroundStyle(.secondary)
                    ActionButton(titleKey: "com_share_now", systemImage: "square.and.arrow.up", tint: .brown) {
                        showShare = true
                    }
                }
            }
            .sheet(isPresented: $showShare) {
                ShareSheet(items: ["Device Playground", URL(string: "https://github.com/tt2819ais-arch/iOS-Device-Playground")!])
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
