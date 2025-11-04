//
//  MessageComposerView.swift
//  Birthday
//
//  Created by Archit Lakhani on 10/30/25.
//

import SwiftUI
import MessageUI

struct MessageComposerView: UIViewControllerRepresentable {
    var recipients: [String]
    var body: String
    var onFinish: (MessageComposeResult) -> Void

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let parent: MessageComposerView
        init(_ parent: MessageComposerView) { self.parent = parent }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            controller.dismiss(animated: true) {
                self.parent.onFinish(result)
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.messageComposeDelegate = context.coordinator
        vc.recipients = recipients
        vc.body = body
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
}
