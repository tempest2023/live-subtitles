# Live Subtitle

A real-time speech-to-text and translation app powered by OpenAI's GPT-4 Realtime API.

## Features

- Real-time speech recognition and translation
- Support for multiple languages
- Dark/Light mode support
- Conversation history
- Share conversation transcripts
- Adaptive UI for different devices

## Technical Details

### Audio Processing
- Uses AVAudioEngine for real-time audio capture
- Configures audio format to match hardware capabilities
- Converts audio to 16kHz sample rate for API compatibility
- Implements efficient memory management for audio buffers

### OpenAI Integration
- Uses WebSocket connection to OpenAI's Realtime API
- Streams audio data in real-time
- Receives simultaneous transcription and translation
- Handles connection state and error management

### Architecture
- Protocol-oriented design with `AudioManagerProtocol`
- MVVM architecture with SwiftUI
- Modular components for reusability
- Proper error handling and user feedback

## Requirements

- iOS 16.0+
- Xcode 15.0+
- OpenAI API Key with access to GPT-4 Realtime API
- Microphone permission

## Setup

1. Clone the repository
2. Open `liveSubtitle.xcodeproj` in Xcode
3. Add your OpenAI API key in `ContentView.swift`
4. Build and run the project

## Usage

1. Select source and target languages
2. Tap the microphone button to start recording
3. Speak into the microphone
4. View real-time transcription and translation
5. Save or share conversations as needed

## Privacy

The app requires microphone access for speech recognition. All audio processing is done through OpenAI's secure API, and no audio data is stored locally except for saved transcriptions.

## License

[Your chosen license]

## Acknowledgments

- OpenAI for providing the GPT-4 Realtime API
- Apple for AVFoundation and SwiftUI frameworks
