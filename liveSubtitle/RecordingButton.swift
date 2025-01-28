import SwiftUI
import AVFoundation

struct RecordingButton: View {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var realtimeService: RealtimeService
    @State private var isProcessing = false
    @State private var showingPermissionAlert = false
    
    let sourceLanguage: String
    let targetLanguage: String
    var onTranscriptionUpdate: (String) -> Void
    var onTranslationUpdate: (String) -> Void
    
    init(sourceLanguage: String,
         targetLanguage: String,
         apiKey: String,
         onTranscriptionUpdate: @escaping (String) -> Void,
         onTranslationUpdate: @escaping (String) -> Void) {
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.onTranscriptionUpdate = onTranscriptionUpdate
        self.onTranslationUpdate = onTranslationUpdate
        _realtimeService = StateObject(wrappedValue: RealtimeService(
            apiKey: apiKey,
            onTranscriptionUpdate: onTranscriptionUpdate,
            onTranslationUpdate: onTranslationUpdate
        ))
    }
    
    var body: some View {
        Button(action: {
            if audioManager.microphoneAccessGranted {
                if audioManager.isRecording {
                    audioManager.stopRecording()
                    realtimeService.disconnect()
                } else {
                    audioManager.startRecording()
                }
            } else {
                showingPermissionAlert = true
            }
        }) {
            ZStack {
                Circle()
                    .fill(audioManager.isRecording ? Color.red : Color.blue)
                    .frame(width: 80, height: 80)
                
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: audioManager.isRecording ? "stop.fill" : "mic.fill")
                        .foregroundColor(.white)
                        .font(.title)
                }
            }
        }
        .alert("Microphone Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings", role: .none) {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(audioManager.errorMessage ?? "Please allow microphone access in settings to use speech recognition.")
        }
        .onChange(of: audioManager.errorMessage) { newValue, oldValue in
            if newValue != nil {
                showingPermissionAlert = true
            }
        }
        .onAppear {
            audioManager.onAudioBuffer = { audioData in
                realtimeService.sendAudioData(
                    audioData,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage
                )
            }
        }
    }
}
