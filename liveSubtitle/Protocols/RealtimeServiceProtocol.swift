import Foundation

protocol RealtimeServiceProtocol: ObservableObject {
    // Published properties
    var isConnected: Bool { get set }
    var error: String? { get set }
    
    // Callbacks
    var onTranscriptionUpdate: ((String) -> Void)? { get set }
    var onTranslationUpdate: ((String) -> Void)? { get set }
    
    // Core functionality
    func sendAudioData(_ audioData: Data, sourceLanguage: String, targetLanguage: String)
    func disconnect()
    
    // Required initializer
    init(apiKey: String,
         onTranscriptionUpdate: ((String) -> Void)?,
         onTranslationUpdate: ((String) -> Void)?)
}

// Response models that can be shared
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