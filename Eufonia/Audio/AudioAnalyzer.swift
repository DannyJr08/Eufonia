//
//  AudioAnalyzer.swift
//  Eufonia
//
//  Created by Juan Daniel Rodriguez Oropeza on 10.12.2024.
//

import AVFoundation

class AudioAnalyzer {
    func calculateTempo(from url: URL) -> Double {
        do {
            // Cargar el archivo de audio
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let frameCount = AVAudioFrameCount(audioFile.length)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
            try audioFile.read(into: buffer)
            
            // Algoritmo simple para detección de tempo:
            guard let channelData =  buffer.floatChannelData?[0] else {
                print("No se pudo obtener los datos del canal.")
                return 0.0
            }
            
            let transients = detectTransients(data: channelData, frameLength: Int(buffer.frameLength))
            let tempo = calculateBPM(from: transients, sampleRate: format.sampleRate)
            return tempo
        } catch {
            print("Error al procesar el archivo de audio para Tempo \(error)")
            return 0.0
        }
    }
    
    // MARK: - Calcular RMS (Root Mean Square Energy)
    func calculateRMS(from url: URL) -> Double {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let frameCount = AVAudioFrameCount(audioFile.length)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
            try audioFile.read(into: buffer)
            
            guard let channelData = buffer.floatChannelData?[0] else {
                print("No se pudo obtener los datos del canal.")
                return 0.0
            }
            
            let frameLength = Int(buffer.frameLength)
            // Convertir el puntero en un buffer manejable
            let channelDataBuffer = UnsafeBufferPointer(start: channelData, count: frameLength)
            let squaredValues = channelDataBuffer.map { $0 * $0 }
            let sumOfSquares = squaredValues.reduce(0, +)
            let rms = sqrt(sumOfSquares / Float(frameLength))
            
            return Double(rms)
        } catch {
            print("Error al procesar el archivo de audio para RMS: \(error)")
            return 0.0
        }
    }
    
    // MARK: - Calcular Pitch (Frecuencia Fundamental)
    func calculatePitch(from url: URL) -> Double {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let frameCount = AVAudioFrameCount(audioFile.length)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
            try audioFile.read(into: buffer)
            
            guard let channelData = buffer.floatChannelData?[0] else {
                print("No se pudo obtener los datos del canal.")
                return 0.0
            }
            
            let pitch = detectPitch(from: channelData, frameLength: Int(buffer.frameLength), sampleRate: format.sampleRate)
            return pitch
        } catch {
            print("Error al procesar el archivo de audio para Pitch: \(error)")
            return 0.0
        }
    }
    
    // MARK: - Métodos Auxiliares
    
    // Detecta transitorios (ataques de sonido) en los datos de audio.
    private func detectTransients(data: UnsafePointer<Float>, frameLength: Int) -> [Int] {
        var transients = [Int]()
        
        for i in 1..<frameLength {
            if data[i] > 0.1 && data[i - 1] <= 0.1 {
                transients.append(i)
            }
        }
        
        return transients
    }
    
    // Calcula BPM (Beats per Minute) a partir de los transitorios detectados.
    private func calculateBPM(from transients: [Int], sampleRate: Double) -> Double {
        guard transients.count > 1 else { return 0.0 }
        var intervals = [Double]()
        
        for i in 1..<transients.count {
            let interval = Double(transients[i] - transients[i - 1]) / sampleRate
            intervals.append(interval)
        }
        
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        let bpm = 60 / avgInterval
        
        return bpm
    }
    
    // Detecta la frecuencia fundamental (pitch) usando un análsisi de autocorrelación.
    private func detectPitch(from data: UnsafePointer<Float>, frameLength: Int, sampleRate: Double) -> Double {
        var maxAutocorr = 0.0
        var fundamentalFreq = 0.0
        
        for lag in 20..<2000 { // Limita el rango de lags
            var autocorr = 0.0
            
            for i in 0..<(frameLength - lag) {
                autocorr += Double(data[i]) * Double(data[i + lag])
            }
            
            if autocorr > maxAutocorr {
                maxAutocorr = autocorr
                fundamentalFreq = sampleRate / Double(lag)
            }
        }
        return fundamentalFreq
    }
}
