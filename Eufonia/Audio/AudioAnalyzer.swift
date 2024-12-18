//
//  AudioAnalyzer.swift
//  Eufonia
//
//  Created by Juan Daniel Rodriguez Oropeza on 10.12.2024.
//

import AVFoundation

class AudioAnalyzer {
    // MARK: - Función auxiliar para cargar el buffer de audio
    private func loadBuffer(from url: URL) throws -> (buffer: AVAudioPCMBuffer, sampleRate: Double, frameLength: Int) {
        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat
        let frameCount = AVAudioFrameCount(audioFile.length)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        
        try audioFile.read(into: buffer)
        
        print("Archivo cargado: \(url.lastPathComponent)")
        print("Formato del archivo: \(format), Frames: \(frameCount)")
        
        return (buffer, format.sampleRate, Int(buffer.frameLength))
    }
    
    // MARK: - Calcular Tempo (BPM)
    func calculateTempo(from url: URL) -> Double {
        do {
            let (buffer, sampleRate, frameLength) = try loadBuffer(from: url)
            guard let channelData = buffer.floatChannelData?[0] else {
                print("No se pudo obtener los datos del canal.")
                return 0.0
            }

            for i in 0..<min(10, frameLength) {
                print("Muestra \(i): \(channelData[i])")
            }
            
            let transients = detectTransients(data: channelData, frameLength: frameLength)
            let tempo = calculateBPM(from: transients, sampleRate: sampleRate)
            
            print("Tempo calculado: \(tempo) BPM")
            return tempo
        } catch {
            print("Error al procesar el archivo para Tempo: \(error)")
            return 0.0
        }
    }
    
    // MARK: - Calcular RMS (Root Mean Square Energy)
    func calculateRMS(from url: URL) -> Double {
        do {
            let (buffer, _, frameLength) = try loadBuffer(from: url)
            guard let channelData = buffer.floatChannelData?[0] else {
                print("No se pudo obtener los datos del canal.")
                return 0.0
            }

            for i in 0..<min(10, frameLength) {
                print("Muestra \(i): \(channelData[i])")
            }
            
            // Cálculo del RMS
            let channelDataBuffer = UnsafeBufferPointer(start: channelData, count: frameLength)
            let squaredValues = channelDataBuffer.map { $0 * $0 }
            let sumOfSquares = squaredValues.reduce(0, +)
            let rms = sqrt(sumOfSquares / Float(frameLength))
            let rmsLinear = sqrt(sumOfSquares / Float(frameLength))
            let rmsDb = 20 * log10(rmsLinear)
            print("RMS en dB: \(rmsDb)")
            
            return Double(rmsDb)
        } catch {
            print("Error al procesar el archivo para RMS: \(error)")
            return 0.0
        }
    }
    
    // MARK: - Calcular Pitch (Frecuencia Fundamental)
    func calculatePitch(from url: URL) -> Double {
        do {
            let (buffer, sampleRate, frameLength) = try loadBuffer(from: url)
            guard let channelData = buffer.floatChannelData?[0] else {
                print("No se pudo obtener los datos del canal.")
                return 0.0
            }

            for i in 0..<min(10, frameLength) {
                print("Muestra \(i): \(channelData[i])")
            }
            
            let pitch = detectPitch(from: channelData, frameLength: frameLength, sampleRate: sampleRate)
            
            print("Pitch calculado: \(pitch) Hz")
            return pitch
        } catch {
            print("Error al procesar el archivo para Pitch: \(error)")
            return 0.0
        }
    }
    
    // MARK: - Métodos Auxiliares
    
    // Detecta transitorios (ataques de sonido) en los datos de audio
    private func detectTransients(data: UnsafePointer<Float>, frameLength: Int) -> [Int] {
        var transients = [Int]()
        
        for i in 1..<frameLength {
            if data[i] > 0.1 && data[i - 1] <= 0.1 {
                transients.append(i)
            }
        }
        
        return transients
    }
    
    // Calcula BPM a partir de los transitorios detectados
    private func calculateBPM(from transients: [Int], sampleRate: Double) -> Double {
        guard transients.count > 1 else { return 0.0 }
        var intervals = [Double]()
        
        for i in 1..<transients.count {
            let interval = Double(transients[i] - transients[i - 1]) / sampleRate
            intervals.append(interval)
        }
        
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        return 60 / avgInterval
    }
    
    // Detecta la frecuencia fundamental (pitch) usando autocorrelación
    private func detectPitch(from data: UnsafePointer<Float>, frameLength: Int, sampleRate: Double) -> Double {
        var maxAutocorr = 0.0
        var fundamentalFreq = 0.0
        
        let minFreq = 80.0
        let maxFreq = 300.0
        let minLag = Int(sampleRate / maxFreq)
        let maxLag = Int(sampleRate / minFreq)
        let lagRange = minLag..<maxLag
        
        for lag in lagRange {
            var sum: Double = 0.0
            for i in 0..<(frameLength - lag) {
                sum += Double(data[i]) * Double(data[i + lag])
            }
            
            if sum > maxAutocorr {
                maxAutocorr = sum
                fundamentalFreq = sampleRate / Double(lag)
            }
        }
        
        // Validar el resultado
        if fundamentalFreq.isNaN || fundamentalFreq < 20 || fundamentalFreq > 2000 {
            print("Pitch inválido detectado.")
            return 0.0
        }
        return fundamentalFreq
    }
}
