import Foundation
import WebKit

class RealtimeService: ObservableObject {
    enum Const {
        static let realtimeWebSocketURL = "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-12-17"
    }
    
    private var webSocket: URLSessionWebSocketTask?
    private let apiKey: String
    
    @Published var isConnected = false
    @Published var error: String?
    
    var onTranscriptionUpdate: ((String) -> Void)?
    var onTranslationUpdate: ((String) -> Void)?
    
    init(apiKey: String,
         onTranscriptionUpdate: ((String) -> Void)? = nil,
         onTranslationUpdate: ((String) -> Void)? = nil) {
        self.apiKey = apiKey
        self.onTranscriptionUpdate = onTranscriptionUpdate
        self.onTranslationUpdate = onTranslationUpdate
        setupWebSocket()
    }
    
    private func setupWebSocket() {
        guard let url = URL(string: Const.realtimeWebSocketURL) else {
            error = "Invalid URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")
        
        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: request)
        
        webSocket?.resume()
        receiveMessage()
        
        isConnected = true
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                // 继续接收下一条消息
                self?.receiveMessage()
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.error = error.localizedDescription
                    self?.isConnected = false
                }
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let response = try? JSONDecoder().decode(RealtimeResponse.self, from: data) else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            if let error = response.error {
                self?.error = error.message
                return
            }
            
            if let textContent = response.text {
                self?.onTranscriptionUpdate?(textContent.original)
                self?.onTranslationUpdate?(textContent.translation)
            }
        }
    }
    
    func sendAudioData(_ audioData: Data, sourceLanguage: String, targetLanguage: String) {
        let event: [String: Any] = [
            "type": "response.create",
            "response": [
                "modalities": ["audio", "text"],
                "instructions": """
                    Listen to the audio and perform these tasks:
                    1. Transcribe the speech in the original language (\(sourceLanguage))
                    2. Translate the transcription to \(targetLanguage)
                    3. Return both the original transcription and translation
                    """
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: event),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            error = "Failed to serialize event"
            return
        }
        
        webSocket?.send(.string(jsonString)) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.error = error.localizedDescription
                }
            }
        }
        
        // 发送音频数据
        webSocket?.send(.data(audioData)) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.error = error.localizedDescription
                }
            }
        }
    }
    
    func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }
    
    deinit {
        disconnect()
    }
}

// Response models
struct RealtimeResponse: Codable {
    let type: String
    let text: TextContent?
    let error: ErrorContent?
    
    struct TextContent: Codable {
        let original: String
        let translation: String
    }
    
    struct ErrorContent: Codable {
        let message: String
        let code: String
    }
} 