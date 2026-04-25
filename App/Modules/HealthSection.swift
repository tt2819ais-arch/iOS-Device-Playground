import SwiftUI
import HealthKit

@MainActor
final class HealthModel: ObservableObject {
    @Published var availableOn = false
    @Published var stepsOn = false
    @Published var hrOn = false

    @Published var available: Bool = HKHealthStore.isHealthDataAvailable()
    @Published var stepsToday: Double?
    @Published var lastHR: Double?
    @Published var status: String = "—"

    private let store = HKHealthStore()

    func requestAuth() async {
        guard available else { status = "unavailable"; return }
        let read: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        do {
            try await store.requestAuthorization(toShare: [], read: read)
            status = "authorized"
        } catch {
            status = error.localizedDescription
        }
    }

    func readSteps() async {
        guard available, let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stat, _ in
            let value = stat?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            DispatchQueue.main.async { self.stepsToday = value }
        }
        store.execute(query)
    }

    func readHeartRate() async {
        guard available, let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
            let bpm = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            DispatchQueue.main.async { self.lastHR = bpm }
        }
        store.execute(q)
    }
}

struct HealthSection: View {
    @StateObject private var m = HealthModel()

    var body: some View {
        VStack(spacing: 16) {
            FeatureCard(titleKey: "health_avail", symbol: "heart.fill", tint: .pink, isOn: $m.availableOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("health_avail_desc").font(.callout).foregroundStyle(.secondary)
                    StatusPill(textKey: m.available ? "granted" : "not_available",
                               systemImage: m.available ? "checkmark.seal.fill" : "xmark.seal.fill",
                               tint: m.available ? .green : .red)
                    if !m.status.isEmpty {
                        Text(m.status).font(.caption.monospaced()).foregroundStyle(.secondary)
                    }
                    ActionButton(titleKey: "health_request_auth", systemImage: "lock.open.fill", tint: .pink) {
                        Task { await m.requestAuth() }
                    }
                }
            }

            FeatureCard(titleKey: "health_steps", symbol: "figure.walk", tint: .pink, isOn: $m.stepsOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("health_steps_desc").font(.callout).foregroundStyle(.secondary)
                    if let s = m.stepsToday {
                        Text("\(Int(s))").font(.largeTitle.monospaced().weight(.bold)).foregroundStyle(.pink)
                    }
                    ActionButton(titleKey: "health_read", systemImage: "arrow.clockwise", tint: .pink) {
                        Task { await m.readSteps() }
                    }
                }
            }

            FeatureCard(titleKey: "health_hr", symbol: "heart.fill", tint: .pink, isOn: $m.hrOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("health_hr_desc").font(.callout).foregroundStyle(.secondary)
                    if let h = m.lastHR {
                        HStack {
                            Image(systemName: "heart.fill").foregroundStyle(.pink)
                            Text("\(Int(h))").font(.largeTitle.monospaced().weight(.bold))
                            Text("BPM").foregroundStyle(.secondary)
                        }
                    }
                    ActionButton(titleKey: "health_read", systemImage: "arrow.clockwise", tint: .pink) {
                        Task { await m.readHeartRate() }
                    }
                    Text("requires_paid_dev_account").font(.caption).foregroundStyle(.orange)
                }
            }
        }
    }
}
