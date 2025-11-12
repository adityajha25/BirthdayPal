//
//  BirthdaySenderView.swift
//  Birthday
//
//  Created by Archit Lakhani on 10/30/25.
//

import SwiftUI
import Contacts
import MessageUI

struct BirthdaySenderView: View {
    @StateObject private var vm = BirthdayMessageViewModel()

    // pretend you already loaded contacts somewhere else
    let allContacts: [CNContact]

    var body: some View {
        VStack(spacing: 16) {
            Button("Send birthday messages for today") {
                vm.startBirthdayFlow(with: allContacts)
            }
            .buttonStyle(.borderedProminent)

            if let err = vm.lastError {
                Text(err)
                    .foregroundColor(.red)
            }
        }
        .sheet(isPresented: $vm.showTemplatePicker) {
            // template picker sheet
            VStack(spacing: 14) {
                Text("Choose a template")
                    .font(.headline)

                ForEach(MessageTone.allCases) { tone in
                    Button(tone.rawValue.capitalized) {
                        vm.userSelectedTemplate(tone)
                    }
                    .buttonStyle(.bordered)
                }

                Button("Cancel") {
                    // if user cancels, just go to next contact
                    vm.composerFinished()
                }
                .foregroundColor(.red)
                .padding(.top)
            }
            .padding()
        }
        .sheet(isPresented: $vm.showComposer) {
            if MFMessageComposeViewController.canSendText() {
                MessageComposerView(
                    recipients: vm.composerRecipients,
                    body: vm.composerBody
                ) { _ in
                    // this is called when user sends/cancels
                    vm.composerFinished()
                }
            } else {
                Text("This device can’t send Messages.")
                    .padding()
            }
        }
    }
}
