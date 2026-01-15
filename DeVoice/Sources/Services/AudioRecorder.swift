import AVFoundation
import AVFAudio
import Foundation

class AudioRecorder: NSObject {
    private var audioRecorder: AVAudioRecorder?
    private let tempFileURL: URL

    override init() {
        tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("devoice_recording.m4a")
        super.init()
    }

    func startRecording() throws {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        // Delete previous recording if exists
        try? FileManager.default.removeItem(at: tempFileURL)

        audioRecorder = try AVAudioRecorder(url: tempFileURL, settings: settings)
        audioRecorder?.record()
    }

    func stopRecording() -> URL? {
        guard let recorder = audioRecorder, recorder.isRecording else {
            return nil
        }

        recorder.stop()
        audioRecorder = nil

        // Verify file exists
        guard FileManager.default.fileExists(atPath: tempFileURL.path) else {
            return nil
        }

        return tempFileURL
    }

    func cleanup() {
        try? FileManager.default.removeItem(at: tempFileURL)
    }

    static func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(macOS 14.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                // For macOS 13, use AVCaptureDevice
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}
