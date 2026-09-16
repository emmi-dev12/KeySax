import Foundation
import AVFoundation
import AppKit
import CoreText
import UniformTypeIdentifiers
import QuartzCore

struct PendingTake: Sendable {
    var wav: URL
    var video: URL?
    var hits: [LetterHit]
    var duration: TimeInterval
    var sentence: String
}

struct LetterHit: Sendable {
    var keyID: String
    var time: TimeInterval
    var end: TimeInterval?
    var glyph: String
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var xFrac: Double
}

enum ExportKind: String, CaseIterable, Identifiable {
    case lettersAudio
    case lettersVideo
    case sentenceAudio
    case sentenceVideo
    case audioOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lettersAudio, .sentenceAudio: return "Video + audio"
        case .lettersVideo, .sentenceVideo: return "Video only"
        case .audioOnly: return "Audio only (WAV)"
        }
    }

    var detail: String {
        switch self {
        case .lettersAudio, .sentenceAudio:
            return "Letters dropping, sentence forming, with sound"
        case .lettersVideo, .sentenceVideo:
            return "The same clip, silent"
        case .audioOnly:
            return "Just the WAV recording"
        }
    }

    var isVideo: Bool { self != .audioOnly }
    var wantsAudio: Bool { self == .lettersAudio || self == .sentenceAudio }
    var extraHold: TimeInterval { (self == .sentenceAudio || self == .sentenceVideo) ? 2.4 : 0.9 }
}

enum LetterVideo {
    static let width = 1080
    static let height = 1080
    static let fps: Int32 = 30
    static let dropSeconds: TimeInterval = 0.48
    static let fadeSeconds: TimeInterval = 0.85

    static func render(
        hits: [LetterHit],
        audioURL: URL?,
        duration: TimeInterval,
        sentence: String,
        kind: ExportKind,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let out = FileManager.default.temporaryDirectory
            .appendingPathComponent("KeySax-letters-\(UUID().uuidString).mp4")
        try? FileManager.default.removeItem(at: out)

        let writer = try AVAssetWriter(outputURL: out, fileType: .mp4)
        let videoIn = makeVideoInput(realtime: false)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoIn,
            sourcePixelBufferAttributes: pixelAttrs()
        )
        writer.add(videoIn)
        guard writer.startWriting() else {
            throw writer.error ?? CocoaError(.fileWriteUnknown)
        }
        writer.startSession(atSourceTime: .zero)

        let total = max(0.4, duration + kind.extraHold)
        let frameCount = max(1, Int((total * Double(fps)).rounded(.up)))
        let frameDur = CMTime(value: 1, timescale: fps)

        for i in 0..<frameCount {
            while !videoIn.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 4_000_000)
            }
            let t = Double(i) / Double(fps)
            guard let buffer = makeFrame(hits: hits, at: t) else { continue }
            adaptor.append(buffer, withPresentationTime: CMTimeMultiply(frameDur, multiplier: Int32(i)))
            if i % 8 == 0 {
                progress(Double(i) / Double(frameCount) * 0.85)
            }
        }
        videoIn.markAsFinished()
        await writer.finishWriting()
        if writer.status != .completed {
            throw writer.error ?? CocoaError(.fileWriteUnknown)
        }

        if kind.wantsAudio, let audioURL {
            let mixed = FileManager.default.temporaryDirectory
                .appendingPathComponent("KeySax-letterclip-\(UUID().uuidString).mp4")
            try await mux(video: out, audio: audioURL, dest: mixed)
            progress(1)
            return mixed
        }
        progress(1)
        _ = sentence
        return out
    }

    static func mux(video: URL, audio: URL, dest: URL) async throws {
        try? FileManager.default.removeItem(at: dest)
        let mix = AVMutableComposition()
        let videoAsset = AVURLAsset(url: video)
        let audioAsset = AVURLAsset(url: audio)
        let vTracks = try await videoAsset.loadTracks(withMediaType: .video)
        let aTracks = try await audioAsset.loadTracks(withMediaType: .audio)
        let vDur = try await videoAsset.load(.duration)
        if let vt = vTracks.first, let track = mix.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try track.insertTimeRange(CMTimeRange(start: .zero, duration: vDur), of: vt, at: .zero)
        }
        if let at = aTracks.first, let track = mix.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            let aDur = try await audioAsset.load(.duration)
            let range = CMTimeRange(start: .zero, duration: min(vDur, aDur))
            try track.insertTimeRange(range, of: at, at: .zero)
        }
        guard let exporter = AVAssetExportSession(asset: mix, presetName: AVAssetExportPresetHighestQuality) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try await exporter.export(to: dest, as: .mp4)
    }

    static func makeFrame(hits: [LetterHit], at t: TimeInterval) -> CVPixelBuffer? {
        var buffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            [
                kCVPixelBufferCGImageCompatibilityKey: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey: true
            ] as CFDictionary,
            &buffer
        )
        guard status == kCVReturnSuccess, let buffer else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let data = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        let ctx = CGContext(
            data: data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        )
        guard let ctx else { return nil }
        paint(ctx, hits: hits, at: t, width: width, height: height)
        return buffer
    }

    static func paint(
        _ ctx: CGContext,
        hits: [LetterHit],
        at t: TimeInterval,
        width: Int,
        height: Int
    ) {
        ctx.setFillColor(CGColor(gray: 0.05, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        ctx.textMatrix = .identity

        if let last = hits.last(where: { $0.time <= t }) {
            ctx.setFillColor(CGColor(red: last.red, green: last.green, blue: last.blue, alpha: 0.14))
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }

        let visible = hits.filter { $0.time <= t }
        for hit in visible {
            let age = t - hit.time
            let p = min(1, age / dropSeconds)
            let ease = 1 - pow(1 - p, 3)
            var alpha: CGFloat = 1
            if let end = hit.end, t > end {
                alpha = max(0, 1 - CGFloat((t - end) / fadeSeconds))
            }
            if alpha <= 0.02 { continue }

            let glyph = hit.glyph == " " ? "␣" : hit.glyph
            let size: CGFloat = glyph.count > 2 ? 120 : 220
            let nsFont = NSFont.systemFont(ofSize: size, weight: .heavy)
            let font = CTFontCreateWithFontDescriptor(nsFont.fontDescriptor, size, nil)
            let color = NSColor(red: hit.red, green: hit.green, blue: hit.blue, alpha: alpha)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color
            ]
            let text = NSAttributedString(string: glyph, attributes: attrs)
            let line = CTLineCreateWithAttributedString(text)
            let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
            let startY = CGFloat(height) * 0.92
            let landY = CGFloat(height) * 0.50
            let y = startY + (landY - startY) * CGFloat(ease)
            let x = CGFloat(hit.xFrac) * CGFloat(width)
            ctx.textPosition = CGPoint(x: x - bounds.midX, y: y - bounds.midY)
            CTLineDraw(line, ctx)
        }

        let sentence = visible.map(\.glyph).joined()
        drawSentenceBar(sentence, in: ctx, width: width, height: height)
    }

    private static func drawSentenceBar(_ sentence: String, in ctx: CGContext, width: Int, height: Int) {
        let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let size: CGFloat = sentence.count > 64 ? 36 : sentence.count > 32 ? 48 : sentence.count > 16 ? 60 : 72
        let nsFont = NSFont.systemFont(ofSize: size, weight: .semibold)
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        para.lineBreakMode = .byWordWrapping
        let attrs: [NSAttributedString.Key: Any] = [
            .font: nsFont,
            .foregroundColor: NSColor(white: 0.95, alpha: 1),
            .paragraphStyle: para
        ]
        let text = NSAttributedString(string: sentence, attributes: attrs)
        let barH: CGFloat = 280
        let rect = CGRect(x: 72, y: 48, width: CGFloat(width) - 144, height: barH)
        let framesetter = CTFramesetterCreateWithAttributedString(text)
        let path = CGPath(rect: rect, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: text.length), path, nil)
        CTFrameDraw(frame, ctx)
    }

    static func makeVideoInput(realtime: Bool) -> AVAssetWriterInput {
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 8_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        let videoIn = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoIn.expectsMediaDataInRealTime = realtime
        return videoIn
    }

    static func pixelAttrs() -> [String: Any] {
        [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ]
    }

    static func lane(for keyID: String, salt: Int) -> Double {
        var h = 2_166_136_261
        for u in keyID.unicodeScalars {
            h ^= Int(u.value)
            h &*= 16_777_619
        }
        h ^= salt &+ 0x9e3779b9
        return 0.14 + Double(abs(h) % 1000) / 1000.0 * 0.72
    }

    @MainActor
    static func savePanel(starting url: URL) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.mpeg4Movie]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = url.lastPathComponent.replacingOccurrences(of: ".mp4", with: "")
        panel.title = "Save export"
        panel.begin { result in
            guard result == .OK, let dest = panel.url else { return }
            try? FileManager.default.removeItem(at: dest)
            try? FileManager.default.copyItem(at: url, to: dest)
        }
    }
}

@MainActor
final class LiveLetterCapture {
    private var writer: AVAssetWriter?
    private var videoIn: AVAssetWriterInput?
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var timer: Timer?
    private var startedAt: TimeInterval = 0
    private var lastTime: TimeInterval = 0
    private(set) var hits: [LetterHit] = []
    private(set) var url: URL?

    var elapsed: TimeInterval {
        guard writer != nil else { return 0 }
        return CACurrentMediaTime() - startedAt
    }

    func start() throws {
        stopTimer()
        hits = []
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("KeySax-live-\(UUID().uuidString).mp4")
        try? FileManager.default.removeItem(at: dest)
        let writer = try AVAssetWriter(outputURL: dest, fileType: .mp4)
        let videoIn = LetterVideo.makeVideoInput(realtime: true)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoIn,
            sourcePixelBufferAttributes: LetterVideo.pixelAttrs()
        )
        writer.add(videoIn)
        guard writer.startWriting() else {
            throw writer.error ?? CocoaError(.fileWriteUnknown)
        }
        writer.startSession(atSourceTime: .zero)
        self.writer = writer
        self.videoIn = videoIn
        self.adaptor = adaptor
        self.url = dest
        startedAt = CACurrentMediaTime()
        lastTime = 0
        appendFrame(at: 0)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(LetterVideo.fps), repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func add(_ hit: LetterHit) {
        hits.append(hit)
    }

    func end(keyID: String, at time: TimeInterval) {
        if let i = hits.lastIndex(where: { $0.keyID == keyID && $0.end == nil }) {
            hits[i].end = time
        }
    }

    func clearHits() {
        hits = []
    }

    func removeLastHit() {
        if !hits.isEmpty { hits.removeLast() }
    }

    func stop(extraHold: TimeInterval = 1.2) async -> URL? {
        stopTimer()
        guard let writer, let videoIn, let adaptor else { return nil }
        let end = max(elapsed, lastTime)
        let tail = Int((extraHold * Double(LetterVideo.fps)).rounded())
        for i in 0...tail {
            let t = end + Double(i) / Double(LetterVideo.fps)
            while !videoIn.isReadyForMoreMediaData {
                try? await Task.sleep(nanoseconds: 4_000_000)
            }
            if let buffer = LetterVideo.makeFrame(hits: hits, at: t) {
                adaptor.append(buffer, withPresentationTime: CMTime(seconds: t, preferredTimescale: 600))
            }
        }
        videoIn.markAsFinished()
        await writer.finishWriting()
        let out = url
        self.writer = nil
        self.videoIn = nil
        self.adaptor = nil
        guard writer.status == .completed else { return nil }
        return out
    }

    private func tick() {
        appendFrame(at: elapsed)
    }

    private func appendFrame(at t: TimeInterval) {
        guard let videoIn, let adaptor else { return }
        guard videoIn.isReadyForMoreMediaData else { return }
        guard let buffer = LetterVideo.makeFrame(hits: hits, at: t) else { return }
        adaptor.append(buffer, withPresentationTime: CMTime(seconds: t, preferredTimescale: 600))
        lastTime = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
