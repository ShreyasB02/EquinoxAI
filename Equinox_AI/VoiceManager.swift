//
//  VoiceManager.swift
//  Equinox_AI
//
//  Created by Shreyas Battula on 1/16/26.
//

import Foundation
import Speech
import AVFoundation

@Observable
class VoiceManager {
    var recognizedText: String = ""
    var isRecording: Bool = false
    var errorMessage: String? = nil
    
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    init(){
        SFSpeechRecognizer.requestAuthorization { (status) in
            switch status {
            case .authorized:
                print("Authorized")
            case .denied:
                print("Denied")
            case .notDetermined:
                print("Not Determined")
            case .restricted:
                print("Restricted")
            @unknown default:
                print("Unknown authorization status")
            }
        }
    }
    
    func stopRecording(){
        isRecording = false
        audioEngine.stop()
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Ignore deactivation errors
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        request = nil
    }
    
    func startRecording() throws{
        if audioEngine.isRunning{
            stopRecording()
            return
        }
        
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            errorMessage = "Speech recognition not authorized."
            return
        }
        guard speechRecognizer?.isAvailable == true else {
            errorMessage = "Speech recognizer is currently unavailable."
            return
        }
        
        recognizedText = ""
        errorMessage = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to configure audio session."
            return
        }
        
        let newRequest = SFSpeechAudioBufferRecognitionRequest()
        newRequest.shouldReportPartialResults = true
        request = newRequest
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: newRequest) { [weak self] result, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let result = result {
                    self.recognizedText = result.bestTranscription.formattedString
                    if result.isFinal {
                        self.stopRecording()
                    }
                }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.stopRecording()
                }
            }
        }
        
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format){
            buffer, _ in
            self.request?.append(buffer)
        }
        audioEngine.prepare()
        do{
            try audioEngine.start()
            isRecording = true
        } catch {
            errorMessage = "Audio Engine couldn't start."
            isRecording = false
            stopRecording()
        }
    }
}
    

