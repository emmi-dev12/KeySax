import Foundation
import AVFoundation
import AppKit
import UniformTypeIdentifiers

final class Recorder: @unchecked Sendable {
    private let lock = NSLock()
    private var file: AVAudioFile?
    private var writing = false
    private let format: AVAudioFormat
    private var converter: AVAudioConverter?
    private var startedAt: Date?

    private(set) var isRecording = false
    private(set) var url: URL?

    init(format: AVAudioFormat) {
        self.format = format
    }

    var elapsed: TimeInterval {
        guard let startedAt, isRecording else { return 0 }
        return Date().timeIntervalSince(startedAt)
    }

    func start() throws {
        lock.lock()
        defer { lock.unlock() }
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("KeySax", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let dest = dir.appendingPathComponent("KeySax-\(stamp).wav")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        file = try AVAudioFile(forWriting: dest, settings: settings)
        url = dest
        writing = true
        isRecording = true
        startedAt = Date()
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        defer { lock.unlock() }
        guard writing, let file else { return }
        do {
            try file.write(from: buffer)
        } catch {
            writing = false
        }
    }

    func stop() -> URL? {
        lock.lock()
        writing = false
        isRecording = false
        let out = url
        file = nil
        lock.unlock()
        return out
    }

    @MainActor
    static func savePanel(starting url: URL) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.wav]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = url.lastPathComponent
        panel.title = "Export KeySax recording"
        panel.begin { result in
            guard result == .OK, let dest = panel.url else { return }
            try? FileManager.default.removeItem(at: dest)
            try? FileManager.default.copyItem(at: url, to: dest)
        }
    }
}

extension UTType {
    static let wav = UTType(filenameExtension: "wav") ?? .audio
}
