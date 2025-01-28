//
//  ContentView.swift
//  liveSubtitle
//
//  Created by RenTao on 1/22/25.
//

import SwiftUI
import Speech

struct ContentView: View {
    @StateObject private var colorSchemeManager = ColorSchemeManager()
    @State private var isRecording = false
    @State private var sourceLanguage = "en-US"
    @State private var targetLanguage = "es"
    @State private var currentSubtitle = ""
    @State private var translatedSubtitle = ""
    @State private var savedConversations: [Conversation] = []
    @State private var showLanguageSelection = false
    @State private var isSourceLanguageSelection = false
    @State private var isTargetLanguageSelection = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Language selection buttons
                HStack(spacing: 15) {
                    Button(action: {
                        isSourceLanguageSelection = true
                    }) {
                        HStack {
                            Text("From: \(Language.nameForCode(sourceLanguage))")
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(buttonBackground())
                        .cornerRadius(10)
                    }
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                    
                    Button(action: {
                        isTargetLanguageSelection = true
                    }) {
                        HStack {
                            Text("To: \(Language.nameForCode(targetLanguage))")
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(buttonBackground())
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Subtitle display area
                VStack {
                    Text(currentSubtitle)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(subtitleBackground(isTranslated: false))
                        .cornerRadius(10)
                    
                    Text(translatedSubtitle)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(subtitleBackground(isTranslated: true))
                        .cornerRadius(10)
                }
                .padding()
                
                // Recording control button
                RecordingButton(
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage,
                    apiKey: "[OpenAI API Key]",
                    onTranscriptionUpdate: { text in
                        currentSubtitle = text
                    },
                    onTranslationUpdate: { text in
                        translatedSubtitle = text
                    }
                )
                
                // History button
                NavigationLink(destination: ConversationHistoryView(conversations: $savedConversations)) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("View History")
                    }
                    .padding()
                    .background(buttonBackground())
                    .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("Live Subtitles 🌟")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        colorSchemeManager.toggleColorScheme()
                    }) {
                        Image(systemName: colorSchemeManager.isDarkMode ? "sun.max.fill" : "moon.fill")
                            .foregroundColor(colorSchemeManager.isDarkMode ? .yellow : .primary)
                    }
                }
            }
            .sheet(isPresented: $isSourceLanguageSelection) {
                LanguageSelectionView(
                    selectedLanguage: $sourceLanguage,
                    isSourceLanguage: true
                )
            }
            .sheet(isPresented: $isTargetLanguageSelection) {
                LanguageSelectionView(
                    selectedLanguage: $targetLanguage,
                    isSourceLanguage: false
                )
            }
        }
        .preferredColorScheme(colorSchemeManager.isDarkMode ? .dark : .light)
    }
    
    // Helper function for button background
    func buttonBackground() -> Color {
        colorSchemeManager.isDarkMode ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1)
    }
    
    // Helper function for subtitle background
    func subtitleBackground(isTranslated: Bool) -> Color {
        if colorSchemeManager.isDarkMode {
            return isTranslated ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3)
        } else {
            return isTranslated ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1)
        }
    }
}

// Supporting structures
struct Conversation: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var sourceLanguage: String
    var targetLanguage: String
    var subtitles: [SubtitleEntry]
}

struct SubtitleEntry: Identifiable, Codable {
    var id = UUID()
    var timestamp: Date
    var originalText: String
    var translatedText: String
}

// Language helper
struct Language {
    static func nameForCode(_ code: String) -> String {
        if code.contains("-") {
            // Handle regional codes like "en-US"
            let components = code.split(separator: "-")
            if let languageCode = components.first {
                let locale = Locale(identifier: String(languageCode))
                var name = locale.localizedString(forLanguageCode: String(languageCode)) ?? code
                
                // Add region if available
                if components.count > 1 {
                    let regionCode = String(components[1])
                    if let regionName = locale.localizedString(forRegionCode: regionCode) {
                        name += " (\(regionName))"
                    }
                }
                return name
            }
        }
        
        // Handle simple language codes
        let locale = Locale(identifier: code)
        return locale.localizedString(forLanguageCode: code) ?? code
    }
}

#Preview {
    ContentView()
}
