//
//  AudioRecorder.swift
//  Eufonia
//
//  Created by Juan Daniel Rodriguez Oropeza on 10.12.2024.
//

import AVFoundation

class AudioRecorder: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder? // Controla la grabación
    private let audioSession = AVAudioSession.sharedInstance() // Sesión de audio
    
    // MARK: - Métodos para grabar audio
    
    func startRecording() {
        do {
            // Configuración de la sesión de audio
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            // Definir el archivo temporal para guardar el audio
            let tempDir = FileManager.default.temporaryDirectory;
            let filePath = tempDir.appendingPathComponent("recording.wav")
            
            // Configuración de grabación
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100, // Frecuencia de muestreo
                AVNumberOfChannelsKey: 1, // Canal mono
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue // Alta calidad
            ]
            
            // Inicializar el grabador
            audioRecorder = try AVAudioRecorder(url: filePath, settings: settings)
            audioRecorder?.record() // Comienza la grabación
            print("Grabación iniciada: \(filePath)")
        } catch {
            print("Error al iniciar la grabación")
        }
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop() // Detener la grabación
        let url = audioRecorder?.url // Recuperar la URL del archivo
        audioRecorder = nil // Liberar recursos
        print("Grabación detenida: \(url?.absoluteString ?? "Sin archivo")")
        return url
    }
    
    func getRecordingDuration(url: URL) -> String {
        do {
            let audioAsset = try AVAudioFile(forReading: url)
            let duration = Double(audioAsset.length) / audioAsset.fileFormat.sampleRate
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%02d:%02d", minutes, seconds)
        } catch {
            print("Error al calcular la duración: \(error)")
            return "00:00"
        }
    }
    
    // MARK: - Manejo de errores
    func requestMicrophoneAccess() {
        // Verifica si el permiso ya fue otorgado o denegado
        let recordPermission = AVAudioApplication.shared.recordPermission
        
        if recordPermission == .granted {
            print("Permiso de micrófono ya otorgado")
        } else {
            AVAudioApplication.requestRecordPermission { granted in
                if granted {
                    print("Permiso de micrófono otorgado")
                } else {
                    print("Permiso de micrófono denegado")
                }
            }
        }
    }
}
