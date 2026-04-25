import SwiftUI
import AVFoundation

@MainActor
final class AudioModel: NSObject, ObservableObject, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    @Published var playbackOn = false
    @Published var recordOn = false
    @Published var backgroundOn = false
    @Published var volumeOn = false

    @Published var currentVolume: Float = AVAudioSession.sharedInstance().outputVolume
    @Published var isRecording = false
    @Published var lastError: String?

    private var player: AVAudioPlayer?
    private var recorder: AVAudioRecorder?

    override init() {
        super.init()
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: [.new], context: nil)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    deinit {
        AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
    }

    override nonisolated func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "outputVolume", let v = change?[.newKey] as? Float {
            Task { @MainActor in self.currentVolume = v }
        }
    }

    func playTone() {
        do {
            try AVAudioSession.sharedInstance().setCategory(backgroundOn ? .playback : .ambient,
                                                            mode: .default,
                                                            options: backgroundOn ? [.mixWithOthers] : [])
            try AVAudioSession.sharedInstance().setActive(true)
            let url = makeToneURL()
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.numberOfLoops = backgroundOn ? -1 : 0
            player?.play()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func stop() {
        player?.stop(); player = nil
    }

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            session.requestRecordPermission { granted in
                Task { @MainActor in
                    guard granted else { self.lastError = "Mic denied"; return }
                    let url = self.recordingURL()
                    let settings: [String: Any] = [
                        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 44100,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ]
                    do {
                        self.recorder = try AVAudioRecorder(url: url, settings: settings)
                        self.recorder?.delegate = self
                        self.recorder?.record()
                        self.isRecording = true
                    } catch {
                        self.lastError = error.localizedDescription
                    }
                }
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func stopRecordingAndPlay() {
        recorder?.stop()
        isRecording = false
        let url = recordingURL()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func recordingURL() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("recording.m4a")
    }

    private func makeToneURL() -> URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = dir.appendingPathComponent("tone.wav")
        if FileManager.default.fileExists(atPath: url.path) { return url }
        // Generate a 1-second 440 Hz sine WAV
        let sampleRate: Double = 44100
        let duration: Double = 1.0
        let frequency: Double = 440
        let sampleCount = Int(sampleRate * duration)
        var samples = [Int16]()
        samples.reserveCapacity(sampleCount)
        for i in 0..<sampleCount {
            let s = sin(2.0 * .pi * frequency * Double(i) / sampleRate)
            samples.append(Int16(s * Double(Int16.max) * 0.5))
        }
        var data = Data()
        let dataSize = sampleCount * 2
        let chunkSize: UInt32 = UInt32(36 + dataSize)
        let byteRate: UInt32 = UInt32(sampleRate) * 1 * 16 / 8
        data.append("RIFF".data(using: .ascii)!)
        var cs = chunkSize.littleEndian; data.append(Data(bytes: &cs, count: 4))
        data.append("WAVE".data(using: .ascii)!)
        data.append("fmt ".data(using: .ascii)!)
        var sub1: UInt32 = 16; data.append(Data(bytes: &sub1, count: 4))
        var fmt: UInt16 = 1; data.append(Data(bytes: &fmt, count: 2))
        var ch: UInt16 = 1; data.append(Data(bytes: &ch, count: 2))
        var sr: UInt32 = UInt32(sampleRate); data.append(Data(bytes: &sr, count: 4))
        var br = byteRate; data.append(Data(bytes: &br, count: 4))
        var ba: UInt16 = 2; data.append(Data(bytes: &ba, count: 2))
        var bps: UInt16 = 16; data.append(Data(bytes: &bps, count: 2))
        data.append("data".data(using: .ascii)!)
        var ds: UInt32 = UInt32(dataSize); data.append(Data(bytes: &ds, count: 4))
        samples.withUnsafeBufferPointer { ptr in
            data.append(Data(buffer: ptr))
        }
        try? data.write(to: url)
        return url
    }
}

struct AudioSection: View {
    @StateObject private var m = AudioModel()

    var body: some View {
        VStack(spacing: 16) {
            FeatureCard(titleKey: "audio_playback", symbol: "speaker.wave.2.fill", tint: .indigo, isOn: $m.playbackOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("audio_playback_desc").font(.callout).foregroundStyle(.secondary)
                    HStack {
                        ActionButton(titleKey: "audio_play_tone", systemImage: "play.fill", tint: .indigo) { m.playTone() }
                        ActionButton(titleKey: "audio_stop", systemImage: "stop.fill", tint: .indigo) { m.stop() }
                    }
                }
            }

            FeatureCard(titleKey: "audio_record", symbol: "mic.fill", tint: .indigo, isOn: $m.recordOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("audio_record_desc").font(.callout).foregroundStyle(.secondary)
                    HStack {
                        ActionButton(titleKey: "audio_record_start", systemImage: "record.circle", tint: .red) { m.startRecording() }
                        ActionButton(titleKey: "audio_record_stop", systemImage: "stop.circle.fill", tint: .indigo) { m.stopRecordingAndPlay() }
                    }
                    if m.isRecording {
                        StatusPill(textKey: "start", systemImage: "waveform", tint: .red)
                    }
                }
            }

            FeatureCard(titleKey: "audio_background", symbol: "moon.zzz.fill", tint: .indigo, isOn: $m.backgroundOn)  {
                Text("audio_background_desc").font(.callout).foregroundStyle(.secondary)
            }

            FeatureCard(titleKey: "audio_volume", symbol: "speaker.wave.3.fill", tint: .indigo, isOn: $m.volumeOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("audio_volume_desc").font(.callout).foregroundStyle(.secondary)
                    HStack {
                        Text("audio_current_volume").font(.callout)
                        Spacer()
                        Text("\(Int(m.currentVolume * 100))%").font(.callout.monospaced())
                    }
                    ProgressView(value: m.currentVolume).tint(.indigo)
                }
            }

            if let err = m.lastError {
                Text(err).font(.caption).foregroundStyle(.red)
            }
        }
    }
}
