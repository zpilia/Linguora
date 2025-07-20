//
//  SpeechRecognizer.swift
//  linguora
//
//  Created by Zoé Pilia on 19/07/2025.
//

import Foundation
import Speech
import AVFoundation

/// Classe observable pour gérer la reconnaissance vocale (iOS)
class SpeechRecognizer: NSObject, ObservableObject {
    var locale: Locale = Locale(identifier: "fr-FR") // Langue de reconnaissance (modifiable dynamiquement)

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest? // Requête de reconnaissance
    private var recognitionTask: SFSpeechRecognitionTask?                  // Tâche active
    private let audioEngine = AVAudioEngine()                              // Moteur audio (capture micro)

    @Published var recognizedText: String = ""     // Texte reconnu mis à jour en temps réel

    // Demande d'autorisation à l'utilisateur pour utiliser la reconnaissance vocale
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

    // Démarre la reconnaissance vocale en continu
    func startRecognition(onResult: @escaping (String) -> Void) {
        stopRecognition() // Nettoie toute tâche précédente

        // Initialise le moteur de reconnaissance avec la langue définie
        guard let speechRecognizer = SFSpeechRecognizer(locale: self.locale), speechRecognizer.isAvailable else {
            print("❌ Reconnaissance vocale non disponible pour la locale \(self.locale.identifier)")
            return
        }

        // Prépare la session audio
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Erreur audioSession : \(error)")
            return
        }

        // Initialise la requête
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else { return }
        request.shouldReportPartialResults = true // permet une mise à jour en direct

        // Configuration du micro
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        // Démarrage du moteur audio
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("❌ Erreur audioEngine.start() : \(error)")
            return
        }

        // Lancement de la tâche de reconnaissance
        recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
            if let result = result {
                let best = result.bestTranscription.formattedString // Résultat le plus probable
                DispatchQueue.main.async {
                    self.recognizedText = best // mise à jour interne
                    onResult(best)             // callback vers l’UI
                }
            }

            // Fin ou erreur
            if error != nil || (result?.isFinal ?? false) {
                self.stopRecognition()
            }
        }
    }

    // Arrête la reconnaissance et libère les ressources
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
