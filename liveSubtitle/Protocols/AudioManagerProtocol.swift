import AVFAudio
import Foundation

protocol AudioManagerProtocol: ObservableObject {
    // Published properties
    var isRecording: Bool { get set }
    var microphoneAccessGranted: Bool { get set }
    var errorMessage: String? { get set }
    
    // Audio buffer callback
    var onAudioBuffer: ((Data) -> Void)? { get set }
    
    // Core functionality
    func startRecording()
    func stopRecording()
    func checkMicrophonePermission()
    
    init()
}