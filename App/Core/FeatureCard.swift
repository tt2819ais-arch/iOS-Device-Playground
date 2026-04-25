import SwiftUI

struct FeatureCard<Content: View>: View {
    let titleKey: LocalizedStringKey
    let symbol: String
    let tint: Color
    @Binding var isOn: Bool
    let onChange: ((Bool) -> Void)?
    @ViewBuilder var content: () -> Content

    @State private var expanded = false
    @Namespace private var ns

    init(titleKey: LocalizedStringKey,
         symbol: String,
         tint: Color = .accentColor,
         isOn: Binding<Bool>,
         onChange: ((Bool) -> Void)? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.titleKey = titleKey
        self.symbol = symbol
        self.tint = tint
        self._isOn = isOn
        self.onChange = onChange
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.22))
                        .frame(width: 44, height: 44)
                    Image(systemName: symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(tint)
                }
                Text(titleKey)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(tint)
                    .onChange(of: isOn) { _, newValue in
                        onChange?(newValue)
                    }
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                        expanded.toggle()
                    }
                } label: {
                    Image(systemName: expanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .symbolEffect(.bounce, value: expanded)
                }
                .buttonStyle(.plain)
            }

            if expanded {
                Divider().opacity(0.4)
                content()
                    .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)),
                                            removal: .opacity))
            }
        }
        .padding(16)
        .liquidGlass(tint: tint)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: expanded)
    }
}

struct StatusPill: View {
    let textKey: LocalizedStringKey
    var systemImage: String? = nil
    var tint: Color = .accentColor
    var body: some View {
        HStack(spacing: 6) {
            if let s = systemImage {
                Image(systemName: s)
            }
            Text(textKey)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.18), in: Capsule())
        .foregroundStyle(tint)
    }
}

struct ActionButton: View {
    let titleKey: LocalizedStringKey
    var systemImage: String? = nil
    var tint: Color = .accentColor
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let s = systemImage { Image(systemName: s) }
                Text(titleKey)
            }
            .font(.callout.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(tint.opacity(0.22), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundStyle(tint)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(tint.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
