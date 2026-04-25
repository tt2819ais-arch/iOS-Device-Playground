import SwiftUI
import CoreBluetooth
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

@MainActor
final class NetworkModel: NSObject, ObservableObject, CBCentralManagerDelegate, URLSessionWebSocketDelegate {
    @Published var httpOn = false
    @Published var wsOn = false
    @Published var bleOn = false
    @Published var wifiOn = false

    @Published var httpResponse: String = ""
    @Published var wsLog: [String] = []
    @Published var bleDevices: [String] = []
    @Published var ssid: String = "—"

    private var central: CBCentralManager?
    private var ws: URLSessionWebSocketTask?

    func sendHTTP() async {
        guard let url = URL(string: "https://api.github.com/zen") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            httpResponse = String(data: data, encoding: .utf8) ?? "—"
        } catch {
            httpResponse = "error: \(error.localizedDescription)"
        }
    }

    func wsConnect() {
        guard let url = URL(string: "wss://echo.websocket.events") else { return }
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        ws = session.webSocketTask(with: url)
        ws?.resume()
        wsLog.append("connecting…")
        listen()
    }
    func wsSend(_ text: String) {
        ws?.send(.string(text)) { err in
            if let err = err { Task { @MainActor in self.wsLog.append("send err: \(err.localizedDescription)") } }
        }
        wsLog.append("→ \(text)")
    }
    func wsDisconnect() {
        ws?.cancel(with: .goingAway, reason: nil)
        ws = nil
        wsLog.append("closed")
    }
    private func listen() {
        ws?.receive { [weak self] result in
            switch result {
            case .success(let msg):
                let s: String
                switch msg {
                case .string(let str): s = str
                case .data(let d): s = "data \(d.count) B"
                @unknown default: s = "?"
                }
                Task { @MainActor in self?.wsLog.append("← \(s)") }
                self?.listen()
            case .failure(let err):
                Task { @MainActor in self?.wsLog.append("err: \(err.localizedDescription)") }
            }
        }
    }

    func bleScan() {
        bleDevices.removeAll()
        if central == nil {
            central = CBCentralManager(delegate: self, queue: .main)
        } else {
            central?.scanForPeripherals(withServices: nil)
        }
    }
    func bleStop() { central?.stopScan() }

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            if central.state == .poweredOn { central.scanForPeripherals(withServices: nil) }
        }
    }
    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? peripheral.identifier.uuidString
        let line = "\(name)  RSSI \(RSSI)"
        Task { @MainActor in
            if !self.bleDevices.contains(line) { self.bleDevices.append(line) }
        }
    }

    func readWiFi() {
        NEHotspotNetwork.fetchCurrent { net in
            DispatchQueue.main.async {
                self.ssid = net?.ssid ?? "—"
            }
        }
    }
}

struct NetworkSection: View {
    @StateObject private var m = NetworkModel()
    @State private var wsText = "ping"

    var body: some View {
        VStack(spacing: 16) {
            FeatureCard(titleKey: "net_http", symbol: "globe", tint: .cyan, isOn: $m.httpOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("net_http_desc").font(.callout).foregroundStyle(.secondary)
                    ActionButton(titleKey: "net_send", systemImage: "paperplane.fill", tint: .cyan) {
                        Task { await m.sendHTTP() }
                    }
                    if !m.httpResponse.isEmpty {
                        Text(m.httpResponse).font(.callout.monospaced()).textSelection(.enabled)
                    }
                }
            }
            FeatureCard(titleKey: "net_ws", symbol: "bolt.horizontal.fill", tint: .cyan, isOn: $m.wsOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("net_ws_desc").font(.callout).foregroundStyle(.secondary)
                    HStack {
                        ActionButton(titleKey: "net_connect", systemImage: "antenna.radiowaves.left.and.right", tint: .cyan) { m.wsConnect() }
                        ActionButton(titleKey: "net_disconnect", systemImage: "xmark.circle", tint: .cyan) { m.wsDisconnect() }
                    }
                    HStack {
                        TextField("message", text: $wsText).textFieldStyle(.roundedBorder)
                        ActionButton(titleKey: "net_send", systemImage: "paperplane", tint: .cyan) { m.wsSend(wsText) }
                    }
                    if !m.wsLog.isEmpty {
                        ScrollView { VStack(alignment: .leading) {
                            ForEach(m.wsLog.indices, id: \.self) { i in
                                Text(m.wsLog[i]).font(.caption.monospaced())
                            }
                        }}.frame(maxHeight: 140)
                    }
                }
            }
            FeatureCard(titleKey: "net_ble", symbol: "wave.3.left", tint: .cyan, isOn: $m.bleOn,
                        onChange: { on in on ? m.bleScan() : m.bleStop() }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("net_ble_desc").font(.callout).foregroundStyle(.secondary)
                    HStack { Text("net_devices_found").font(.callout.weight(.semibold)); Spacer(); Text("\(m.bleDevices.count)").font(.callout.monospaced()) }
                    ScrollView { VStack(alignment: .leading) {
                        ForEach(m.bleDevices.indices, id: \.self) { i in
                            Text(m.bleDevices[i]).font(.caption.monospaced())
                        }
                    }}.frame(maxHeight: 140)
                }
            }
            FeatureCard(titleKey: "net_wifi", symbol: "wifi", tint: .cyan, isOn: $m.wifiOn,
                        onChange: { on in if on { m.readWiFi() } }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("net_wifi_desc").font(.callout).foregroundStyle(.secondary)
                    HStack { Text("SSID").font(.callout.weight(.semibold)); Spacer(); Text(m.ssid).font(.callout.monospaced()) }
                    ActionButton(titleKey: "trigger", systemImage: "arrow.clockwise", tint: .cyan) { m.readWiFi() }
                }
            }
        }
    }
}
