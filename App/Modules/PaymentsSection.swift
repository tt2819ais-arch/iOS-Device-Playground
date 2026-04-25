import SwiftUI
import StoreKit
import PassKit

struct PaymentsSection: View {
    @State private var iapOn = false
    @State private var subsOn = false
    @State private var payOn = false
    @State private var status = "—"
    @State private var canPay: Bool = PKPaymentAuthorizationController.canMakePayments()

    var body: some View {
        VStack(spacing: 16) {
            FeatureCard(titleKey: "pay_iap", symbol: "bag.fill", tint: .green, isOn: $iapOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("pay_iap_desc").font(.callout).foregroundStyle(.secondary)
                    Text("requires_paid_dev_account").font(.caption).foregroundStyle(.orange)
                    ActionButton(titleKey: "pay_check", systemImage: "magnifyingglass", tint: .green) {
                        Task {
                            do {
                                let products = try await Product.products(for: ["com.example.product1"])
                                status = "products: \(products.count)"
                            } catch {
                                status = error.localizedDescription
                            }
                        }
                    }
                    Text(status).font(.caption.monospaced())
                }
            }
            FeatureCard(titleKey: "pay_subs", symbol: "repeat.circle.fill", tint: .green, isOn: $subsOn) {
                Text("pay_subs_desc").font(.callout).foregroundStyle(.secondary)
            }
            FeatureCard(titleKey: "pay_applepay", symbol: "applelogo", tint: .green, isOn: $payOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("pay_applepay_desc").font(.callout).foregroundStyle(.secondary)
                    StatusPill(textKey: canPay ? "granted" : "not_available",
                               systemImage: canPay ? "checkmark.seal.fill" : "xmark.seal.fill",
                               tint: canPay ? .green : .red)
                    if canPay {
                        ApplePayButton().frame(height: 44)
                    }
                }
            }
        }
    }
}

struct ApplePayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> PKPaymentButton {
        PKPaymentButton(paymentButtonType: .plain, paymentButtonStyle: .automatic)
    }
    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}
}
