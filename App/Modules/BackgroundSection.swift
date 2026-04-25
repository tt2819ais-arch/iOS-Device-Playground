import SwiftUI
import BackgroundTasks
import CoreLocation

struct BackgroundSection: View {
    @State private var fetchOn = false
    @State private var procOn = false
    @State private var geoOn = false
    @State private var status = "—"
    private static let fetchID = "com.tt2819ais.deviceplayground.fetch"
    private static let procID = "com.tt2819ais.deviceplayground.processing"

    var body: some View {
        VStack(spacing: 16) {
            FeatureCard(titleKey: "bg_fetch", symbol: "arrow.triangle.2.circlepath", tint: .gray, isOn: $fetchOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("bg_fetch_desc").font(.callout).foregroundStyle(.secondary)
                    ActionButton(titleKey: "bg_schedule", systemImage: "calendar", tint: .gray) {
                        let req = BGAppRefreshTaskRequest(identifier: Self.fetchID)
                        req.earliestBeginDate = Date(timeIntervalSinceNow: 60)
                        do { try BGTaskScheduler.shared.submit(req); status = "scheduled" }
                        catch { status = error.localizedDescription }
                    }
                    Text(status).font(.caption.monospaced()).foregroundStyle(.secondary)
                }
            }
            FeatureCard(titleKey: "bg_processing", symbol: "cpu.fill", tint: .gray, isOn: $procOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("bg_processing_desc").font(.callout).foregroundStyle(.secondary)
                    ActionButton(titleKey: "bg_schedule", systemImage: "calendar", tint: .gray) {
                        let req = BGProcessingTaskRequest(identifier: Self.procID)
                        req.requiresNetworkConnectivity = true
                        do { try BGTaskScheduler.shared.submit(req); status = "scheduled" }
                        catch { status = error.localizedDescription }
                    }
                }
            }
            FeatureCard(titleKey: "bg_geo", symbol: "location.viewfinder", tint: .gray, isOn: $geoOn,
                        onChange: { on in
                            let m = CLLocationManager()
                            if on { m.startMonitoringSignificantLocationChanges() }
                            else { m.stopMonitoringSignificantLocationChanges() }
                        }) {
                Text("bg_geo_desc").font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}
