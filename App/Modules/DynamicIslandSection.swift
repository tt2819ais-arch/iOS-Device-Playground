import SwiftUI
import ActivityKit

@MainActor
final class DynamicIslandModel: ObservableObject {
    @Published var liveOn: Bool = false
    @Published var status: String = ""
    @Published var lastError: String?
    @Published var progress: Double = 0.1
    @Published var emoji: String = "🚀"
    @Published var title: String = "Device Playground"
    @Published var subtitle: String = "Live Activity demo"
    @Published var sessionName: String = "Playground"

    private var activityID: String?
    private var ticker: Timer?

    deinit { ticker?.invalidate() }

    var areEnabled: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    func start() {
        guard areEnabled else {
            lastError = "Live Activities disabled in system Settings."
            liveOn = false
            return
        }
        let attrs = PlaygroundActivityAttributes(sessionName: sessionName)
        let initial = PlaygroundActivityAttributes.ContentStateData(
            title: title, subtitle: subtitle, progress: progress, emoji: emoji
        )
        do {
            let activity = try Activity<PlaygroundActivityAttributes>.request(
                attributes: attrs,
                content: .init(state: initial, staleDate: nil),
                pushType: nil
            )
            activityID = activity.id
            status = "running id=\(activity.id.prefix(6))…"
            liveOn = true
            startTicker()
        } catch {
            lastError = error.localizedDescription
            status = "failed"
            liveOn = false
        }
    }

    func update() async {
        guard let id = activityID,
              let activity = Activity<PlaygroundActivityAttributes>.activities.first(where: { $0.id == id })
        else { return }
        let next = PlaygroundActivityAttributes.ContentStateData(
            title: title, subtitle: subtitle, progress: progress, emoji: emoji
        )
        await activity.update(.init(state: next, staleDate: nil))
        status = "updated \(Int(progress * 100))%"
    }

    func stop() async {
        ticker?.invalidate()
        ticker = nil
        guard let id = activityID,
              let activity = Activity<PlaygroundActivityAttributes>.activities.first(where: { $0.id == id })
        else {
            status = "not running"
            liveOn = false
            return
        }
        await activity.end(nil, dismissalPolicy: .immediate)
        // If a new activity was started during the await, leave its state alone.
        if activityID == id {
            activityID = nil
            status = "stopped"
            liveOn = false
        }
    }

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.progress = min(1.0, self.progress + 0.07)
                await self.update()
                if self.progress >= 1.0 {
                    self.ticker?.invalidate()
                }
            }
        }
    }
}

struct DynamicIslandSection: View {
    @StateObject private var model = DynamicIslandModel()

    var body: some View {
        VStack(spacing: 16) {
            FeatureCard(titleKey: "di_live_activity",
                        symbol: "rectangle.inset.filled.and.cursorarrow",
                        tint: .blue,
                        isOn: $model.liveOn,
                        onChange: { on in
                            if on { model.start() } else {
                                Task { await model.stop() }
                            }
                        }) {
                VStack(alignment: .leading, spacing: 12) {
                    if !model.areEnabled {
                        StatusPill(textKey: "di_disabled",
                                   systemImage: "exclamationmark.triangle.fill",
                                   tint: .orange)
                    }
                    StatusPill(textKey: LocalizedStringKey(model.status),
                               systemImage: "info.circle", tint: .blue)
                    if let err = model.lastError {
                        StatusPill(textKey: LocalizedStringKey(err),
                                   systemImage: "xmark.octagon", tint: .red)
                    }

                    LabeledContent("di_session_name") {
                        TextField("Playground", text: $model.sessionName)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("di_title") {
                        TextField("title", text: $model.title)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("di_subtitle") {
                        TextField("subtitle", text: $model.subtitle)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("di_progress")
                        Spacer()
                        Text("\(Int(model.progress * 100))%")
                            .monospacedDigit()
                    }
                    Slider(value: $model.progress, in: 0...1)

                    HStack(spacing: 8) {
                        ForEach(["🚀","🎮","📦","🔥","⚡️","🍕","🎯","🛰️"], id: \.self) { e in
                            Button(e) { model.emoji = e }
                                .font(.title2)
                                .padding(6)
                                .background(model.emoji == e ?
                                            Color.accentColor.opacity(0.25) : .clear,
                                            in: Circle())
                        }
                    }

                    HStack {
                        ActionButton(titleKey: "di_update", systemImage: "arrow.clockwise", tint: .blue) {
                            Task { await model.update() }
                        }
                        ActionButton(titleKey: "di_stop", systemImage: "stop.fill", tint: .red) {
                            Task { await model.stop() }
                        }
                    }
                }
            }

            // Local visual preview that mimics the Dynamic Island look,
            // useful on devices without the hardware island.
            FeatureCard(titleKey: "di_preview",
                        symbol: "iphone.gen3",
                        tint: .indigo,
                        isOn: .constant(true),
                        onChange: nil) {
                IslandPreview(state: .init(title: model.title,
                                           subtitle: model.subtitle,
                                           progress: model.progress,
                                           emoji: model.emoji),
                              session: model.sessionName)
            }
        }
    }
}

private struct IslandPreview: View {
    let state: PlaygroundActivityAttributes.ContentStateData
    let session: String

    var body: some View {
        VStack(spacing: 14) {
            Text("di_preview_compact").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Text(state.emoji).font(.system(size: 18))
                Spacer()
                Text("\(Int(state.progress * 100))%")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .frame(maxWidth: 220)
            .background(Capsule().fill(Color.black))
            .foregroundStyle(.white)

            Text("di_preview_expanded").font(.caption).foregroundStyle(.secondary).padding(.top, 6)
            HStack(alignment: .top, spacing: 12) {
                Text(state.emoji).font(.system(size: 32))
                VStack(alignment: .leading, spacing: 4) {
                    Text(session).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                    Text(state.title).font(.headline)
                    Text(state.subtitle).font(.caption).foregroundStyle(.secondary)
                    ProgressView(value: state.progress).tint(.white)
                }
                Spacer()
                Text("\(Int(state.progress * 100))%")
                    .font(.title3.bold())
                    .monospacedDigit()
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color.black))
            .foregroundStyle(.white)
        }
    }
}
