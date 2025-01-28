import SwiftUI

struct ConversationHistoryView: View {
    @Binding var conversations: [Conversation]
    @State private var selectedConversations: Set<UUID> = []
    @State private var showShareSheet = false
    
    var body: some View {
        List(conversations) { conversation in
            ConversationRow(conversation: conversation)
                .swipeActions {
                    Button(role: .destructive) {
                        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                            conversations.remove(at: index)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        selectedConversations = [conversation.id]
                        showShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .tint(.blue)
                }
        }
        .navigationTitle("Conversation History")
        .toolbar {
            if !conversations.isEmpty {
                Button(action: {
                    showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(conversations: conversations.filter { selectedConversations.contains($0.id) })
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(conversation.date, style: .date)
                .font(.headline)
            Text("\(Language.nameForCode(conversation.sourceLanguage)) → \(Language.nameForCode(conversation.targetLanguage))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let conversations: [Conversation]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let text = formatConversationsForExport(conversations)
        let av = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        return av
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    
    private func formatConversationsForExport(_ conversations: [Conversation]) -> String {
        // Format conversations for export (you can customize this format)
        conversations.map { conversation in
            """
            Date: \(conversation.date)
            From: \(Language.nameForCode(conversation.sourceLanguage))
            To: \(Language.nameForCode(conversation.targetLanguage))
            
            \(conversation.subtitles.map { subtitle in
                """
                [\(subtitle.timestamp)]
                Original: \(subtitle.originalText)
                Translated: \(subtitle.translatedText)
                """
            }.joined(separator: "\n\n"))
            """
        }.joined(separator: "\n\n---\n\n")
    }
} 