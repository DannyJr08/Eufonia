//
//  AudioPlayer.swift
//  Eufonia
//
//  Created by Juan Daniel Rodriguez Oropeza on 17.12.2024.
//

import AVFoundation

class AudioPlayer: NSObject, ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying: Bool = false
    @Published var currentRecording: Recording?
    
    @Published var currentTime: Double = 0.0
    @Published var duration: Double = 0.0
    private var timer: Timer?
    
    func prepare(url: URL) {
        // Intentar cargar el AVAudioPlayer para leer la duración
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            duration = player.duration
            currentTime = 0.0
        } catch {
            print("Error al preparar audio: \(error)")
        }
    }
    
    func play(url: URL, recording: Recording) {
        if isPlaying, currentRecording?.id == recording.id {
            stop()
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            duration = audioPlayer?.duration ?? 0.0
            currentTime = 0.0
            isPlaying = true
            currentRecording = recording
            audioPlayer?.play()
            
            // Iniciar un timer para actualizar currentTime
            startTimer()
        } catch {
            print("Error al reproducir audio: \(error)")
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        currentRecording = nil
        stopTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
            if !player.isPlaying {
                self.stopTimer()
                self.isPlaying = false
                self.currentRecording = nil
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentRecording = nil
        stopTimer()
    }
}
