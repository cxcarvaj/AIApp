//
//  AppleIntelligenceVM.swift
//  AIApp
//
//  Created by Carlos Xavier Carvajal Villegas on 13/6/25.
//


import SwiftUI
import Translation
import AVFoundation
import Speech

@Observable
final class AppleIntelligenceVM {
    var text = ""
    var translation = ""
    var configuration: TranslationSession.Configuration?
    
    var isGenerating = false
    var isTalking = false
    var isRecording = false
    
    private var synthesizer = AVSpeechSynthesizer()
    
    private var audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es_ES"))
    private var avSession: AVAudioSession?
    
    var imageURL: URL?
    var prompt = ""
    
    func configureAudioSession() {
        AVAudioApplication.requestRecordPermission { granted in
            if granted {
                print("JDJDJD")
            }
        }
        
       // synthesizer.delegate = self
    }
    
    func makeTranslation() {
        if configuration == nil {
            configuration = TranslationSession.Configuration(source: Locale.Language(identifier: "es"),
                                                             target: Locale.Language(identifier: "en"))
        } else {
            configuration?.invalidate()
        }
    }
    
    func speak() {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        let voices = AVSpeechSynthesisVoice.speechVoices()
        print(voices)
        utterance.voice = voices.first { $0.language == "es-ES" }
        synthesizer.speak(utterance)
        isTalking = true
    }
    
    func dontSpeak() {
        synthesizer.stopSpeaking(at: .word)
    }
    
    func startRecording() {
        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .notDetermined {
            SFSpeechRecognizer.requestAuthorization { status in
                if status == .authorized {
                    print("Chupi")
                }
            }
        }
        
        guard !audioEngine.isRunning else { return }
        
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            guard let result else { return }
            
            self.text = result.bestTranscription.formattedString
            
            if error != nil || result.isFinal {
                inputNode.removeTap(onBus: 0)
                self.stopRecording()
            }
        }
        
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, _) in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            avSession = AVAudioSession.sharedInstance()
            try avSession?.setCategory(.record, mode: .measurement, options: .duckOthers)
            try avSession?.setActive(true, options: .notifyOthersOnDeactivation)
            
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Error al iniciar la grabación")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        request?.endAudio()
        self.request = nil
        self.recognitionTask = nil
        self.isRecording = false
        self.avSession = nil
        isRecording = false
    }
    
//    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
//        Task { @MainActor in
//            isTalking = false
//        }
//    }
}
