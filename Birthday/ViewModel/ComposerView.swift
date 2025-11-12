import SwiftUI
import MessageUI

struct MessageComposerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = MFMessageComposeViewController
    typealias Context = UIViewControllerRepresentableContext<MessageComposerView>

    var recipients: [String]
    var body: String
    var onFinish: (MessageComposeResult) -> Void

    // Coordinator to bridge UIKit delegate back to SwiftUI
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let parent: MessageComposerView

        init(parent: MessageComposerView) {
            self.parent = parent
        }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            controller.dismiss(animated: true) {
                self.parent.onFinish(result)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.messageComposeDelegate = context.coordinator
        vc.recipients = recipients
        vc.body = body
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {
        // In case you ever change recipients/body while the sheet is up
        uiViewController.recipients = recipients
        uiViewController.body = body
    }
}
