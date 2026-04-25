import Foundation
import ActivityKit

public struct PlaygroundActivityAttributes: ActivityAttributes {
    public typealias ContentState = ContentStateData

    public struct ContentStateData: Codable, Hashable {
        public var title: String
        public var subtitle: String
        public var progress: Double
        public var emoji: String

        public init(title: String, subtitle: String, progress: Double, emoji: String) {
            self.title = title
            self.subtitle = subtitle
            self.progress = progress
            self.emoji = emoji
        }
    }

    public var sessionName: String

    public init(sessionName: String) {
        self.sessionName = sessionName
    }
}
