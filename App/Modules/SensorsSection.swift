import SwiftUI
import CoreMotion

@MainActor
final class SensorsModel: ObservableObject {
    @Published var accelOn = false
    @Published var gyroOn = false
    @Published var baroOn = false
    @Published var pedoOn = false

    @Published var accel: CMAcceleration = .init(x: 0, y: 0, z: 0)
    @Published var gyro: CMRotationRate = .init(x: 0, y: 0, z: 0)
    @Published var pressureKPa: Double = 0
    @Published var relAlt: Double = 0
    @Published var stepsToday: Int = 0

    private let motion = CMMotionManager()
    private let altimeter = CMAltimeter()
    private let pedometer = CMPedometer()

    func startAccel() {
        motion.accelerometerUpdateInterval = 1.0/30
        motion.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            if let a = data?.acceleration { self?.accel = a }
        }
    }
    func stopAccel() { motion.stopAccelerometerUpdates() }

    func startGyro() {
        motion.gyroUpdateInterval = 1.0/30
        motion.startGyroUpdates(to: .main) { [weak self] data, _ in
            if let r = data?.rotationRate { self?.gyro = r }
        }
    }
    func stopGyro() { motion.stopGyroUpdates() }

    func startBaro() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
            self?.pressureKPa = data?.pressure.doubleValue ?? 0
            self?.relAlt = data?.relativeAltitude.doubleValue ?? 0
        }
    }
    func stopBaro() { altimeter.stopRelativeAltitudeUpdates() }

    func startPedo() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        let start = Calendar.current.startOfDay(for: Date())
        pedometer.startUpdates(from: start) { [weak self] data, _ in
            DispatchQueue.main.async { self?.stepsToday = data?.numberOfSteps.intValue ?? 0 }
        }
    }
    func stopPedo() { pedometer.stopUpdates() }
}

struct SensorsSection: View {
    @StateObject private var m = SensorsModel()

    var body: some View {
        VStack(spacing: 16) {
            FeatureCard(titleKey: "sens_accel", symbol: "move.3d", tint: .teal, isOn: $m.accelOn,
                        onChange: { on in on ? m.startAccel() : m.stopAccel() }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("sens_accel_desc").font(.callout).foregroundStyle(.secondary)
                    axesRow(x: m.accel.x, y: m.accel.y, z: m.accel.z, fmt: "%+.2f g")
                }
            }
            FeatureCard(titleKey: "sens_gyro", symbol: "gyroscope", tint: .teal, isOn: $m.gyroOn,
                        onChange: { on in on ? m.startGyro() : m.stopGyro() }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("sens_gyro_desc").font(.callout).foregroundStyle(.secondary)
                    axesRow(x: m.gyro.x, y: m.gyro.y, z: m.gyro.z, fmt: "%+.2f rad/s")
                }
            }
            FeatureCard(titleKey: "sens_baro", symbol: "barometer", tint: .teal, isOn: $m.baroOn,
                        onChange: { on in on ? m.startBaro() : m.stopBaro() }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("sens_baro_desc").font(.callout).foregroundStyle(.secondary)
                    HStack { Text("kPa").font(.callout.weight(.semibold)); Spacer(); Text(String(format: "%.2f", m.pressureKPa)).font(.callout.monospaced()) }
                    HStack { Text("Δ alt, m").font(.callout.weight(.semibold)); Spacer(); Text(String(format: "%+.2f", m.relAlt)).font(.callout.monospaced()) }
                }
            }
            FeatureCard(titleKey: "sens_pedo", symbol: "figure.walk", tint: .teal, isOn: $m.pedoOn,
                        onChange: { on in on ? m.startPedo() : m.stopPedo() }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("sens_pedo_desc").font(.callout).foregroundStyle(.secondary)
                    HStack { Text("steps").font(.callout.weight(.semibold)); Spacer(); Text("\(m.stepsToday)").font(.title3.monospaced().weight(.bold)) }
                }
            }
        }
    }

    private func axesRow(x: Double, y: Double, z: Double, fmt: String) -> some View {
        HStack(spacing: 12) {
            ForEach(["X": x, "Y": y, "Z": z].sorted(by: { $0.key < $1.key }), id: \.key) { k, v in
                VStack {
                    Text(k).font(.caption.weight(.bold)).foregroundStyle(.secondary)
                    Text(String(format: fmt, v)).font(.callout.monospaced())
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}
