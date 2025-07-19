//
//  SpeechRecognizer.swift
//  linguora
//
//  Created by Zoé Pilia on 19/07/2025.
//

import Foundation
import Speech
import AVFoundation

class SpeechRecognizer: NSObject, ObservableObject {
    var locale: Locale = Locale(identifier: "fr-FR") // 🔁 Langue dynamique
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var recognizedText: String = ""

    // 🔐 Demande d'autorisation
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("✅ Autorisation accordée")
                case .denied:
                    print("❌ Accès à la reconnaissance vocale refusé.")
                case .restricted:
                    print("⚠️ Reconnaissance vocale restreinte sur cet appareil.")
                case .notDetermined:
                    print("❓ Autorisation non déterminée.")
                @unknown default:
                    print("Erreur inconnue")
                }
            }
        }
    }

    // ▶️ Commencer la reconnaissance
    func startRecognition(onResult: @escaping (String) -> Void) {
        stopRecognition()

        guard let speechRecognizer = SFSpeechRecognizer(locale: self.locale), speechRecognizer.isAvailable else {
            print("❌ Reconnaissance vocale non disponible pour la locale \(self.locale.identifier)")
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Erreur audioSession : \(error)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else { return }

        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("❌ Erreur audioEngine.start() : \(error)")
            return
        }

        recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
            if let result = result {
                let best = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.recognizedText = best
                    onResult(best)
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                self.stopRecognition()
            }
        }
    }

    // ⏹️ Stop
    func stopRecognition() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
    }
}
