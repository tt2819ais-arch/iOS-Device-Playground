import SwiftUI

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveBackground()
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(FeatureCategory.allCases) { category in
                            NavigationLink(value: category) {
                                CategoryRow(category: category)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("app_title")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.thinMaterial)
            }
            .navigationDestination(for: FeatureCategory.self) { category in
                CategoryView(category: category)
            }
        }
    }
}

private struct CategoryRow: View {
    let category: FeatureCategory
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [category.tint, category.tint.opacity(0.6)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                Image(systemName: category.symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(category.titleKey)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(category.subtitleKey)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.callout.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .liquidGlass(tint: category.tint)
    }
}
