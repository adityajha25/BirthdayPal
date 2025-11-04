import Foundation
import SwiftUI
import UIKit
import Combine

/// Helper to access Apple's Writing Tools for birthday message rewriting
/// Note: Writing Tools in iOS 18+ work through the UI, not as a direct API
/// This provides a SwiftUI view that enables Writing Tools on text
@available(iOS 18.0, *)
struct WritingToolsTextEditor: UIViewRepresentable {
    @Binding var text: String
    var onTextChange: ((String) -> Void)?
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.text = text
        textView.isEditable = true
        textView.delegate = context.coordinator
        
        // Enable Writing Tools
        textView.writingToolsBehavior = .complete
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: WritingToolsTextEditor
        
        init(_ parent: WritingToolsTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.onTextChange?(textView.text)
        }
    }
}

/// View for rewriting birthday messages using Apple's Writing Tools
@available(iOS 18.0, *)
struct BirthdayMessageRewriterView: View {
    @Binding var message: String
    let desiredTone: String
    var onComplete: ((String) -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Rewrite your message")
                .font(.headline)
            
            Text("Tap 'Select Text' then choose 'Writing Tools' → 'Rewrite' → '\(toneDisplayName)'")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            WritingToolsTextEditor(text: $message) { newText in
                onComplete?(newText)
            }
            .frame(height: 200)
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 2)
            )
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                Text("Instructions:")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text("1. Long-press the text above")
                Text("2. Tap 'Select All'")
                Text("3. Tap 'Writing Tools'")
                Text("4. Choose 'Rewrite' → '\(toneDisplayName)'")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var toneDisplayName: String {
        switch desiredTone.lowercased() {
        case "casual", "friendly":
            return "Friendly"
        case "formal", "professional":
            return "Professional"
        case "concise", "short":
            return "Concise"
        default:
            return "Friendly"
        }
    }
}

/// Manager for programmatically initiating birthday message rewriting
@available(iOS 18.0, *)
class BirthdayMessageRewriter: ObservableObject {
    @Published var currentMessage: String = ""
    @Published var showRewriteSheet: Bool = false
    
    private var desiredTone: String = "friendly"
    private var onCompletionHandler: ((String) -> Void)?
    
    /// Initiates the rewriting process by presenting the Writing Tools UI
    /// - Parameters:
    ///   - originalMessage: The birthday message to rewrite
    ///   - tone: Desired tone (friendly, professional, concise)
    ///   - completion: Called when user finishes editing
    func rewriteMessage(
        originalMessage: String,
        tone: String,
        completion: @escaping (String) -> Void
    ) {
        self.currentMessage = originalMessage
        self.desiredTone = tone
        self.onCompletionHandler = completion
        self.showRewriteSheet = true
    }
    
    /// Creates the sheet view for rewriting
    @ViewBuilder
    func makeRewriteView() -> some View {
        BirthdayMessageRewriterView(
            message: Binding(
                get: { self.currentMessage },
                set: { self.currentMessage = $0 }
            ),
            desiredTone: desiredTone
        ) { rewrittenMessage in
            self.onCompletionHandler?(rewrittenMessage)
        }
    }
    
    /// Call this when user dismisses the sheet
    func handleDismiss() {
        onCompletionHandler?(currentMessage)
        showRewriteSheet = false
    }
}

