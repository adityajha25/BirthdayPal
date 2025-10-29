//
//  ContentView.swift
//  IOS_Club_Project
//
//  Created by Aditya Jha    on 10/29/25.
//

import SwiftUI

struct ContentView: View {
    @State private var counter = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to My Playground App!")
                    .font(.title)
                    .multilineTextAlignment(.center)
                
                Text("Button tapped \(counter) times")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    counter += 1
                }) {
                    Text("Tap Me")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

#Preview {
    ContentView()
}
