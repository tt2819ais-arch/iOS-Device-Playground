import SwiftUI
import CoreLocation

@MainActor
final class LocationModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentOn = false
    @Published var backgroundOn = false
    @Published var geofenceOn = false
    @Published var compassOn = false

    @Published var lastLocation: CLLocation?
    @Published var heading: CLHeading?
    @Published var regionStatus: String = "—"
    @Published var authorization: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorization = manager.authorizationStatus
    }

    func requestWhenInUse() { manager.requestWhenInUseAuthorization() }
    func requestAlways() { manager.requestAlwaysAuthorization() }

    func startCurrent() { manager.requestLocation() }
    func startBackground() { manager.allowsBackgroundLocationUpdates = true; manager.startUpdatingLocation() }
    func stopBackground() { manager.stopUpdatingLocation() }
    func startCompass() { manager.startUpdatingHeading() }
    func stopCompass() { manager.stopUpdatingHeading() }

    func startGeofence() {
        guard let loc = lastLocation else { startCurrent(); return }
        let region = CLCircularRegion(center: loc.coordinate, radius: 50, identifier: "DP_REGION")
        region.notifyOnExit = true; region.notifyOnEntry = true
        manager.startMonitoring(for: region)
        regionStatus = "monitoring"
    }
    func stopGeofence() {
        for r in manager.monitoredRegions { manager.stopMonitoring(for: r) }
        regionStatus = "stopped"
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in self.authorization = manager.authorizationStatus }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in self.lastLocation = loc }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in self.heading = newHeading }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in self.regionStatus = "entered: \(region.identifier)" }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task { @MainActor in self.regionStatus = "exited: \(region.identifier)" }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.regionStatus = "error: \(error.localizedDescription)" }
    }
}

struct LocationSection: View {
    @StateObject private var m = LocationModel()

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                StatusPill(textKey: m.authorization == .authorizedAlways || m.authorization == .authorizedWhenInUse ? "granted" : "denied",
                           systemImage: "location.fill",
                           tint: m.authorization == .denied ? .red : .green)
                Spacer()
                Button { m.requestWhenInUse() } label: { Label("loc_request_when_in_use", systemImage: "location.circle") }
                    .buttonStyle(.bordered).controlSize(.small)
                Button { m.requestAlways() } label: { Label("loc_request_always", systemImage: "location.fill") }
                    .buttonStyle(.bordered).controlSize(.small)
            }

            FeatureCard(titleKey: "loc_current", symbol: "location.fill", tint: .green, isOn: $m.currentOn,
                        onChange: { on in if on { m.startCurrent() } }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("loc_current_desc").font(.callout).foregroundStyle(.secondary)
                    if let l = m.lastLocation {
                        coordRow("loc_lat", value: l.coordinate.latitude)
                        coordRow("loc_lon", value: l.coordinate.longitude)
                        coordRow("loc_alt", value: l.altitude)
                        coordRow("loc_acc", value: l.horizontalAccuracy)
                    }
                    ActionButton(titleKey: "trigger", systemImage: "location.fill", tint: .green) { m.startCurrent() }
                }
            }

            FeatureCard(titleKey: "loc_background", symbol: "location.viewfinder", tint: .green, isOn: $m.backgroundOn,
                        onChange: { on in on ? m.startBackground() : m.stopBackground() }) {
                Text("loc_background_desc").font(.callout).foregroundStyle(.secondary)
            }

            FeatureCard(titleKey: "loc_geofence", symbol: "circle.dashed", tint: .green, isOn: $m.geofenceOn,
                        onChange: { on in on ? m.startGeofence() : m.stopGeofence() }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("loc_geofence_desc").font(.callout).foregroundStyle(.secondary)
                    HStack {
                        Text("loc_geofence_status").font(.callout.weight(.semibold))
                        Spacer()
                        Text(m.regionStatus).font(.callout.monospaced())
                    }
                }
            }

            FeatureCard(titleKey: "loc_compass", symbol: "safari.fill", tint: .green, isOn: $m.compassOn,
                        onChange: { on in on ? m.startCompass() : m.stopCompass() }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("loc_compass_desc").font(.callout).foregroundStyle(.secondary)
                    if let h = m.heading {
                        HStack {
                            Text("loc_heading").font(.callout.weight(.semibold))
                            Spacer()
                            Text("\(Int(h.magneticHeading))°").font(.callout.monospaced())
                            Image(systemName: "location.north.line.fill")
                                .rotationEffect(.degrees(-h.magneticHeading))
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
    }

    private func coordRow(_ key: LocalizedStringKey, value: Double) -> some View {
        HStack {
            Text(key).font(.callout.weight(.semibold))
            Spacer()
            Text(String(format: "%.5f", value)).font(.callout.monospaced())
        }
    }
}
