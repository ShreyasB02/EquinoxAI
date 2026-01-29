//import SwiftUI
//import UIKit
//import FoundationModels
//
//struct ChatView: View {
//    // MARK: - Text
//    @State private var prompt = ""
//    @State private var response = "Ask EquinoxAI something…"
//    @State private var isThinking = false
//
//    // MARK: - Voice
//    @State private var voiceManager = VoiceManager()
//
//    // MARK: - Image
//    @State private var selectedImage: UIImage?
//    @State private var isCameraOpen = false
//    private let visionManager = VisionManager()
//
//    // MARK: - LLM
//    @State private var modelSession = LanguageModelSession()
//
//    var body: some View {
//        VStack(spacing: 16) {
//
//            // AI RESPONSE
//            ScrollView {
//                Text(response)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding()
//            }
//            .frame(height: 250)
//            .background(Color(.secondarySystemBackground))
//            .cornerRadius(10)
//
//            // IMAGE PREVIEW
//            if let image = selectedImage {
//                Image(uiImage: image)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(height: 150)
//                    .cornerRadius(10)
//            }
//
//            // INPUT ROW
//            HStack {
//
//                TextField("Ask EquinoxAI...", text: $prompt)
//                    .textFieldStyle(.roundedBorder)
//                    .disabled(isThinking || voiceManager.isRecording)
//
//                // 🎙 Microphone
//                Button {
//                    handleVoiceInput()
//                } label: {
//                    Image(systemName: voiceManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
//                        .font(.system(size: 32))
//                        .foregroundColor(voiceManager.isRecording ? .red : .blue)
//                }
//
//                HStack {
//                    // 📷 Camera
//                    Button {
//                        isCameraOpen = true
//                    } label: {
//                        Image(systemName: "camera.fill")
//                            .font(.system(size: 28))
//                    }
//
//                    // 🖼 Photo Library
//                    PhotoLibraryPicker(selectedImage: $selectedImage)
//                }
//                .padding(.horizontal)
//            }
//
//            // LIVE VOICE PREVIEW
//            if voiceManager.isRecording {
//                Text("Hearing: \(voiceManager.recognizedText)")
//                    .font(.caption)
//                    .foregroundColor(.gray)
//            }
//
//            // GENERATE
//            Button("Generate") {
//                Task {
//                    await generateResponse()
//                }
//            }
//            .buttonStyle(.borderedProminent)
//            .disabled(prompt.isEmpty || isThinking)
//        }
//        .padding()
//        .sheet(isPresented: $isCameraOpen) {
//            CameraPicker(selectedImage: $selectedImage)
//        }
//        .onChange(of: selectedImage) { _, newImage in
//            if let image = newImage {
//                Task {
//                    await analyzeImage(image)
//                }
//            }
//        }
//    }
//    func handleVoiceInput() {
//        do {
//            if voiceManager.isRecording {
//                try voiceManager.stopRecording()
//                prompt = voiceManager.recognizedText
//            } else {
//                try voiceManager.startRecording()
//            }
//        } catch {
//            response = "Audio error: \(error.localizedDescription)"
//        }
//    }
//    func analyzeImage(_ image: UIImage) async {
//        isThinking = true
//        response = "Analyzing image…"
//
//        let visionText = await visionManager.analyzeImage(image)
//
//        prompt = """
//        \(visionText)
//
//        Please help me understand this image.
//        """
//
//        isThinking = false
//    }
//    func generateResponse() async {
//        isThinking = true
//        response = ""
//
//        do {
//            let result = try await modelSession.respond(to: prompt)
//            response = result.content
//        } catch {
//            response = "Error: \(error.localizedDescription)"
//        }
//
//        isThinking = false
//    }
//
//
//}
//
import SwiftUI
import SwiftData
import FoundationModels
import PhotosUI

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext // Access the database
    @State private var memoryManager: MemoryManager?
    
    // Inputs
    @State private var prompt: String = ""
    @State private var response: String = "Waiting for input..."
    @State private var isThinking: Bool = false
    
    // Multimodal
    @State private var voiceManager = VoiceManager()
    @State private var visionManager = VisionManager()
    @State private var selectedImage: UIImage?
    @State private var isCameraOpen: Bool = false
    @State private var photosPickerItem: PhotosPickerItem?
    
    // Brain
    @State private var modelSession: LanguageModelSession?

    var body: some View {
        VStack(spacing: 15) {
            
            // Output
            ScrollView {
                Text(response)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            
            // Image Preview
            if let image = selectedImage {
                HStack {
                    Image(uiImage: image).resizable().scaledToFit().frame(height: 100)
                    Button("Remove") { selectedImage = nil }
                    Spacer()
                }
            }

            // Controls
            HStack {
                Button(action: { isCameraOpen = true }) { Image(systemName: "camera.fill") }
                PhotosPicker(selection: $photosPickerItem, matching: .images) { Image(systemName: "photo.fill") }
                
                Button(action: toggleRecording) {
                    Image(systemName: voiceManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .foregroundColor(voiceManager.isRecording ? .red : .blue)
                }
            }
            .font(.title2)
            .padding(.top)

            // Input
            HStack {
                TextField("Ask EquinoxAI...", text: $prompt)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isThinking)
                
                Button(action: { Task { await processRequest() } }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.largeTitle)
                }
                .disabled(prompt.isEmpty && selectedImage == nil)
            }
        }
        .padding()
        .task {
            // Initialize Brain & Memory
            await prepareModel()
            self.memoryManager = MemoryManager(modelContext: modelContext)
        }
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self), let ui = UIImage(data: data) {
                    selectedImage = ui
                }
            }
        }
        .onChange(of: voiceManager.recognizedText) { _, val in
            if voiceManager.isRecording { prompt = val }
        }
        .sheet(isPresented: $isCameraOpen) {
            CameraPicker(selectedImage: $selectedImage)
        }
    }
    
    // MARK: - Core Logic
    
    func prepareModel() async {
        do {
            self.modelSession = LanguageModelSession()
            self.response = "EquinoxAI is ready."
        } catch {
            self.response = "Error: \(error.localizedDescription)"
        }
    }
    
    func toggleRecording() {
        do {
            if voiceManager.isRecording {
                // If stopRecording can throw, handle it here
                try voiceManager.stopRecording()
                prompt = voiceManager.recognizedText
                // Optionally auto-send after voice stops
                // Task { await processRequest() }
            } else {
                try voiceManager.startRecording()
                response = "🎙️ Listening…"
            }
        } catch {
            // Provide user-visible feedback and log the error
            response = "Audio error: \(error.localizedDescription)"
            print("Voice recording error: \(error)")
        }
    }
    
    func processRequest() async {
        guard let session = modelSession, let memories = memoryManager else { return }
        isThinking = true
        
        // 1. Check if user wants to SAVE a memory
        // Simple heuristic: If it starts with "Remember", save it.
        if prompt.lowercased().hasPrefix("remember") {
            memories.remember(prompt)
            response = "✅ I have saved that to my memory."
            prompt = ""
            isThinking = false
            return
        }
        
        // 2. Retrieve existing memories
        let memoryContext = memories.recallAll()
        
        // 3. Process Image (if any)
        var imageContext = ""
        if let image = selectedImage {
            response = "👀 Analyzing image..."
            imageContext = "\n[Image Context: \(await visionManager.analyzeImage(image))]"
        }
        
        // 4. Construct the Super-Prompt
        // We wrap the user's prompt with the Memory Context
        let fullPrompt = """
        \(memoryContext)
        \(imageContext)
        
        User Question: \(prompt)
        """
        
        // 5. Generate
        response = ""
        do {
            let result = try await session.respond(to: fullPrompt)
            response = result.content
        } catch {
            response = "Error: \(error.localizedDescription)"
        }
        
        isThinking = false
    }
}

