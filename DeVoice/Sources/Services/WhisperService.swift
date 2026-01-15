import Foundation

struct WhisperResponse: Codable {
    let text: String
}

struct WhisperError: Codable {
    let error: WhisperErrorDetail
}

struct WhisperErrorDetail: Codable {
    let message: String
}

class WhisperService {
    private let apiKey: String
    private let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func transcribe(audioURL: URL) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add file
        let audioData = try Data(contentsOf: audioURL)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // Add model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)

        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WhisperServiceError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw WhisperServiceError.invalidAPIKey
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(WhisperError.self, from: data) {
                throw WhisperServiceError.apiError(errorResponse.error.message)
            }
            throw WhisperServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }

        let result = try JSONDecoder().decode(WhisperResponse.self, from: data)
        return result.text
    }
}

enum WhisperServiceError: LocalizedError {
    case invalidAPIKey
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API Key. Check your settings."
        case .invalidResponse:
            return "Invalid server response."
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}
