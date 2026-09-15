import Foundation
import AVFoundation
import AppKit
import CoreText
import UniformTypeIdentifiers

struct PendingTake: Sendable {
    var wav: URL
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
        case .lettersAudio: return "Letters + audio"
        case .lettersVideo: return "Letters only (video)"
        case .sentenceAudio: return "Sentence + audio"
        case .sentenceVideo: return "Sentence only (video)"
        case .audioOnly: return "Audio only (WAV)"
        }
    }

    var detail: String {
        switch self {
        case .lettersAudio: return "One letter per frame, with sound"
        case .lettersVideo: return "One letter per frame, silent"
        case .sentenceAudio: return "Letters, then the full sentence, with sound"
        case .sentenceVideo: return "The spelled sentence, silent"
        case .audioOnly: return "Just the WAV recording"
        }
    }

    var isVideo: Bool { self != .audioOnly }
}

enum LetterVideo {
    static let width = 1080
    static let height = 1080
    static let fps: Int32 = 30
    static let hold: TimeInterval = 0.28
    static let sentenceHold: TimeInterval = 3.2

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
        videoIn.expectsMediaDataInRealTime = false
        let attrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoIn,
            sourcePixelBufferAttributes: attrs
        )
        writer.add(videoIn)
        guard writer.startWriting() else {
            throw writer.error ?? CocoaError(.fileWriteUnknown)
        }
        writer.startSession(atSourceTime: .zero)

        let letters = kind == .sentenceVideo ? 0 : duration
        let tail = (kind == .sentenceAudio || kind == .sentenceVideo) ? sentenceHold : 0
        let total = max(0.4, letters + tail)
        let frameCount = max(1, Int((total * Double(fps)).rounded(.up)))
        let frameDur = CMTime(value: 1, timescale: fps)

        for i in 0..<frameCount {
            while !videoIn.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 4_000_000)
            }
            let t = Double(i) / Double(fps)
            let showSentence = t >= letters && tail > 0
            let hit = showSentence ? nil : activeHit(hits, at: t)
            guard let buffer = makeFrame(hit: hit, sentence: showSentence ? sentence : nil) else { continue }
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

        let wantsAudio = (kind == .lettersAudio || kind == .sentenceAudio)
        if wantsAudio, let audioURL {
            let mixed = FileManager.default.temporaryDirectory
                .appendingPathComponent("KeySax-letterclip-\(UUID().uuidString).mp4")
            try await mux(video: out, audio: audioURL, dest: mixed)
            progress(1)
            return mixed
        }
        progress(1)
        return out
    }

    private static func activeHit(_ hits: [LetterHit], at t: TimeInterval) -> LetterHit? {
        let live = hits.filter { hit in
            let end = hit.end ?? (hit.time + hold)
            let holdEnd = max(end, hit.time + hold)
            return t >= hit.time && t < holdEnd
        }
        return live.last
    }

    private static func makeFrame(hit: LetterHit?, sentence: String?) -> CVPixelBuffer? {
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
        ctx.setFillColor(CGColor(gray: 0.05, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        ctx.textMatrix = .identity

        if let sentence, !sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            drawSentence(sentence, in: ctx)
            return buffer
        }

        guard let hit else { return buffer }
        ctx.setFillColor(CGColor(red: hit.red, green: hit.green, blue: hit.blue, alpha: 0.16))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        let glyph = hit.glyph == " " ? "␣" : hit.glyph
        let size: CGFloat = glyph.count > 2 ? 220 : 560
        let nsFont = NSFont.systemFont(ofSize: size, weight: .heavy)
        let font = CTFontCreateWithFontDescriptor(nsFont.fontDescriptor, size, nil)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(red: hit.red, green: hit.green, blue: hit.blue, alpha: 1)
        ]
        let text = NSAttributedString(string: glyph, attributes: attrs)
        let line = CTLineCreateWithAttributedString(text)
        let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
        ctx.textPosition = CGPoint(
            x: CGFloat(width) / 2 - bounds.midX,
            y: CGFloat(height) / 2 - bounds.midY
        )
        CTLineDraw(line, ctx)
        return buffer
    }

    private static func drawSentence(_ sentence: String, in ctx: CGContext) {
        let size: CGFloat = sentence.count > 48 ? 54 : sentence.count > 24 ? 72 : 96
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
        let rect = CGRect(x: 80, y: 220, width: CGFloat(width) - 160, height: 640)
        let framesetter = CTFramesetterCreateWithAttributedString(text)
        let path = CGPath(rect: rect, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: text.length), path, nil)
        CTFrameDraw(frame, ctx)
    }

    private static func mux(video: URL, audio: URL, dest: URL) async throws {
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
