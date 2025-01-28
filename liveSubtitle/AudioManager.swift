import AVFAudio
import Foundation

class AudioManager: AudioManagerProtocol {
    private var audioEngine: AVAudioEngine
    private var inputNode: AVAudioInputNode
    private var converter: AVAudioConverter?
    private let bufferSize: AVAudioFrameCount = 1024
    private let targetSampleRate: Double = 16000
    
    @Published var isRecording = false
    @Published var audioData: [Float] = []
    @Published var microphoneAccessGranted = false
    @Published var errorMessage: String?
    
    var onAudioBuffer: ((Data) -> Void)?
    
    required init() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode
        checkMicrophonePermission()
    }
    
    func checkMicrophonePermission() {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                microphoneAccessGranted = true
            case .denied:
                microphoneAccessGranted = false
                errorMessage = "Microphone access denied. Please allow access in settings."
            case .undetermined:
                AVAudioApplication.requestRecordPermission { [weak self] granted in
                    DispatchQueue.main.async {
                        self?.microphoneAccessGranted = granted
                        if !granted {
                            self?.errorMessage = "Microphone permission is required for speech recognition."
                        }
                    }
                }
            @unknown default:
                microphoneAccessGranted = false
                errorMessage = "Unknown microphone permission status."
            }
        } else {
            // Fallback for iOS 16 and earlier
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                microphoneAccessGranted = true
            case .denied:
                microphoneAccessGranted = false
                errorMessage = "Microphone access denied. Please allow access in settings."
            case .undetermined:
                AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                    DispatchQueue.main.async {
                        self?.microphoneAccessGranted = granted
                        if !granted {
                            self?.errorMessage = "Microphone permission is required for speech recognition."
                        }
                    }
                }
            @unknown default:
                microphoneAccessGranted = false
                errorMessage = "Unknown microphone permission status."
            }
        }
    }
    
    private func configureAudioFormat() -> (input: AVAudioFormat, output: AVAudioFormat?) {
        // 获取硬件的原生格式
        let hardwareFormat = inputNode.inputFormat(forBus: 0)
        
        print("[DEBUG] Hardware format: \(hardwareFormat)")
        
        // 输出格式：使用目标采样率（16kHz）
        let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        )
        
        print("[DEBUG] Output format: \(outputFormat ?? AVAudioFormat())")
        
        return (hardwareFormat, outputFormat)
    }
    
    private func convertBuffer(_ buffer: AVAudioPCMBuffer, to outputFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: AVAudioFrameCount(
                Double(buffer.frameLength) * (outputFormat.sampleRate / buffer.format.sampleRate)
            )
        ) else {
            return nil
        }
        
        guard let converter = self.converter else {
            return nil
        }
        
        var error: NSError?
        let status = converter.convert(
            to: outputBuffer,
            error: &error,
            withInputFrom: { inNumPackets, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
        )
        
        if let error = error {
            print("[ERROR] Conversion error: \(error)")
            return nil
        }
        
        guard status != .error else {
            return nil
        }
        
        return outputBuffer
    }
    
    func startRecording() {
        guard microphoneAccessGranted else {
            errorMessage = "Please grant microphone access first."
            return
        }
        
        if isRecording {
            stopRecording()
        }
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            
            let formats = configureAudioFormat()
            let inputFormat = formats.input
            guard let outputFormat = formats.output else {
                errorMessage = "Failed to configure audio format"
                return
            }
            
            // 创建转换器
            guard let audioConverter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
                errorMessage = "Failed to create audio converter"
                return
            }
            self.converter = audioConverter
            
            audioEngine.prepare()
            
            // 使用完全相同的硬件输入格式安装 tap
            inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
                guard let self = self,
                      let outputBuffer = self.convertBuffer(buffer, to: outputFormat) else {
                    return
                }
                
                // 获取转换后的音频数据
                let audioBuffer = outputBuffer.audioBufferList.pointee.mBuffers
                var data = Data(count: Int(audioBuffer.mDataByteSize))
                
                data.withUnsafeMutableBytes { ptr in
                    guard let dest = ptr.baseAddress else { return }
                    memcpy(dest, audioBuffer.mData, Int(audioBuffer.mDataByteSize))
                }
                
                DispatchQueue.main.async {
                    self.onAudioBuffer?(data)
                }
            }
            
            try audioEngine.start()
            
            isRecording = true
            errorMessage = nil
            
        } catch {
            errorMessage = "Error starting recording: \(error.localizedDescription)"
            print("[ERROR] starting audio engine: \(error)")
            stopRecording()
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        
        if inputNode.numberOfInputs > 0 {
            inputNode.removeTap(onBus: 0)
        }
        
        converter = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Error stopping recording: \(error.localizedDescription)"
            print("[ERROR] stopping audio session: \(error)")
        }
        
        isRecording = false
    }
    
    deinit {
        stopRecording()
    }
}
