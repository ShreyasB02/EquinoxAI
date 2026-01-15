//
//  ContentView.swift
//  Equinox_AI
//
//  Created by Shreyas Battula on 1/14/26.
//

import SwiftUI
import FoundationModels
import Playgrounds

struct GenerativeView: View {
    private let model = SystemLanguageModel.default

    var body: some View {
        switch model.availability {
        case .available:
            ChatView()

        case .unavailable(.deviceNotEligible):
            Text("This device does not support Apple Intelligence.")

        case .unavailable(.appleIntelligenceNotEnabled):
            Text("Please enable Apple Intelligence in Settings.")

        case .unavailable(.modelNotReady):
            ProgressView("Loading model...")

        case .unavailable:
            Text("Model unavailable due to an unknown error.")
        }
    }
}


struct ChatView: View {
    @State private var prompt = ""
    @State private var response = "Ask EquinoxAI something…"
    @State private var isThinking = false

    @State private var modelSession = LanguageModelSession()

    var body: some View {
        VStack(spacing: 16) {

            ScrollView {
                Text(response)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(height: 300)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)

            TextField("Ask EquinoxAI...", text: $prompt)
                .textFieldStyle(.roundedBorder)
                .disabled(isThinking)

            Button("Generate") {
                Task {
                    await generateResponse()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(prompt.isEmpty || isThinking)
        }
        .padding()
    }

    func generateResponse() async {
        isThinking = true
        response = ""

        do {
            let result = try await modelSession.respond(to: prompt)
            response = result.content
        } catch {
            response = "Error: \(error.localizedDescription)"
        }

        isThinking = false
    }
}
