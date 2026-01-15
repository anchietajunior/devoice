import Foundation
import Combine

enum VoiceState {
    case idle
    case recording
    case processing
}

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    @Published private(set) var state: VoiceState = .idle
    @Published var apiKey: String = ""
    @Published var errorMessage: String?

    private init() {
        loadAPIKey()
    }

    func setState(_ newState: VoiceState) {
        state = newState
    }

    func setError(_ message: String) {
        errorMessage = message
    }

    func clearError() {
        errorMessage = nil
    }

    private func loadAPIKey() {
        apiKey = KeychainHelper.load(key: "openai_api_key") ?? ""
    }

    func saveAPIKey(_ key: String) {
        apiKey = key
        KeychainHelper.save(key: "openai_api_key", value: key)
    }
}
