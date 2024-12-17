//
//  PredictionResultView.swift
//  Eufonia
//
//  Created by Juan Daniel Rodriguez Oropeza on 13.12.2024.
//

import SwiftUI

struct PredictionResultView: View {
    let recording: Recording? // Recibe la grabación seleccionada
    @StateObject private var audioPlayer = AudioPlayer()
    
    // Valores calculados a partir del análisis de audio
    let tempo: Double
    let pitch: Double
    let rms: Double
    
    // Resultados de los modelos Core ML
    let tempoPrediction: String
    let pitchPrediction: String
    let rmsPrediction: String
    
    @State private var showNoRecordingAlert = false
    
    var body: some View {
        ZStack {
            // Fondo degradado similar a un estilo más elaborado
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Título principal
                    Text("Resultados de las Predicciones")
                        .font(.largeTitle)
                        .bold()
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.top, 40)
                    
                    // Tarjeta con información de la grabación
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Información de la Grabación:")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        Text("📜 Nombre: \(recording?.name ?? "Desconocido")")
                            .font(.subheadline)
                        Text("📅 Fecha: \(recording?.date.formatted() ?? "Desconocido")")
                            .font(.subheadline)
                        Text("⏱ Duración: \(recording?.duration ?? "Desconocido")")
                            .font(.subheadline)
                        Text("🔮 Predicción: \(recording?.predictionResult ?? "Desconocido")")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground).opacity(0.9))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Botón de reproducción
                    VStack {
                        Button(action: {
                            if let recording = recording {
                                audioPlayer.play(url: recording.url, recording: recording)
                            } else {
                                // Mostrar alerta cuando no haya grabación
                                showNoRecordingAlert = true
                            }
                        }) {
                            Image(systemName: audioPlayer.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .foregroundColor(.blue)
                                .padding()
                        }
                        
                        // Barra de progreso si hay duración
                        if audioPlayer.duration > 0 {
                            VStack(spacing: 10) {
                                ProgressView(value: audioPlayer.currentTime, total: audioPlayer.duration)
                                    .accentColor(.blue)
                                
                                HStack {
                                    Text(formatTime(audioPlayer.currentTime)) // Tiempo transcurrido
                                    Spacer()
                                    Text("-\(formatTime(audioPlayer.duration - audioPlayer.currentTime))") // Tiempo restante
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                            .background(Color(UIColor.systemBackground).opacity(0.9))
                            .cornerRadius(15)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Información del análisis de audio
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Características Analizadas:")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        Text("🎶 Tempo (BPM): \(String(format: "%.2f", tempo))")
                        Text("🎼 Pitch (Hz): \(String(format: "%.2f", pitch))")
                        Text("🔊 RMS (db): \(String(format: "%.4f", rms))")
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground).opacity(0.9))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Resultados de las predicciones
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Resultados de los Modelos:")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        Text("🚀 Predicción del Tempo: \(tempoPrediction)")
                            .foregroundColor(.blue)
                        Text("🎯 Predicción del Pitch: \(pitchPrediction)")
                            .foregroundColor(.green)
                        Text("💥 Predicción del RMS: \(rmsPrediction)")
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground).opacity(0.9))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .alert("No hay grabación disponible", isPresented: $showNoRecordingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("No se pudo reproducir nada porque no existe ninguna grabación seleccionada.")
        }
        .onAppear {
            // Preparar duración al aparecer la vista
            if let recording = recording {
                audioPlayer.prepare(url: recording.url)
            }
        }
    }
    
    // Función para formatear el tiempo (segundos) a mm:ss
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
