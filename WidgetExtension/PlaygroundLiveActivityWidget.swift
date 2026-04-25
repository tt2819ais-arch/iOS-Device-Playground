import ActivityKit
import WidgetKit
import SwiftUI

struct PlaygroundLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PlaygroundActivityAttributes.self) { context in
            // Lock screen / notification banner presentation
            LockScreenLiveActivityView(state: context.state, attributes: context.attributes)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.emoji)
                        .font(.system(size: 38))
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.attributes.sessionName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("\(Int(context.state.progress * 100))%")
                            .font(.title3.bold())
                            .monospacedDigit()
                    }
                    .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.title)
                            .font(.headline)
                        Text(context.state.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ProgressView(value: context.state.progress)
                            .tint(.accentColor)
                    }
                    .padding(.horizontal, 6)
                }
            } compactLeading: {
                Text(context.state.emoji)
                    .font(.system(size: 16))
            } compactTrailing: {
                Text("\(Int(context.state.progress * 100))%")
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
            } minimal: {
                Text(context.state.emoji)
                    .font(.system(size: 14))
            }
            .keylineTint(.accentColor)
        }
    }
}

struct LockScreenLiveActivityView: View {
    let state: PlaygroundActivityAttributes.ContentStateData
    let attributes: PlaygroundActivityAttributes

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Text(state.emoji)
                .font(.system(size: 44))
            VStack(alignment: .leading, spacing: 4) {
                Text(attributes.sessionName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(state.title)
                    .font(.headline)
                Text(state.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ProgressView(value: state.progress)
                    .tint(.white)
            }
            Spacer(minLength: 0)
            Text("\(Int(state.progress * 100))%")
                .font(.title3.bold())
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .padding(16)
    }
}
