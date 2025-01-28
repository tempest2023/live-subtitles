import SwiftUI

struct LanguageSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedLanguage: String
    let isSourceLanguage: Bool
    
    // Supported languages with their codes
    let languages: [(name: String, code: String)] = [
        ("English (US)", "en-US"),
        ("English (UK)", "en-GB"),
        ("简体中文", "zh-CN"),
        ("繁体中文", "zh-TW"),
        ("Spanish", "es"),
        ("French", "fr"),
        ("German", "de"),
        ("Japanese", "ja"),
        ("Korean", "ko"),
        ("Italian", "it"),
        ("Russian", "ru"),
        ("Portuguese", "pt"),
    ]
    
    var body: some View {
        NavigationStack {
            List(languages, id: \.code) { language in
                Button(action: {
                    selectedLanguage = language.code
                    dismiss()
                }) {
                    HStack {
                        Text(language.name)
                        Spacer()
                        if selectedLanguage == language.code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            }
            .navigationTitle(isSourceLanguage ? "Source Language" : "Target Language")
            .toolbar {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
} 