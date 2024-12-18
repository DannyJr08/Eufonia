//
//  PredictionResultView.swift
//  Eufonia
//
//  Created by Juan Daniel Rodriguez Oropeza on 13.12.2024.
//

import SwiftUI

struct PredictionResultView: View {
    @Environment(\.dismiss) var dismiss // Permite cerrar la vista sheet
    
    let recording: Recording?
    @StateObject private var audioPlayer = AudioPlayer()
    
    // Analyzed audio values
    let tempo: Double
    let pitch: Double
    let rms: Double
    
    // ML model results
    let tempoPrediction: String
    let pitchPrediction: String
    let rmsPrediction: String
    
    @State private var showNoRecordingAlert = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("Prediction Results")
                        .font(.largeTitle)
                        .bold()
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.top, 40)
                        .accessibilityLabel("Prediction Results")
                    
                    // Recording info card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recording Information:")
                            .font(.headline)
                            .padding(.bottom, 5)
                            .accessibilityLabel("Recording Information")
                        
                        Text("📜 Name: \(recording?.name ?? "Unknown")")
                            .font(.subheadline)
                            .accessibilityLabel("Name: \(recording?.name ?? "Unknown")")
                        Text("📅 Date: \(recording?.date.formatted() ?? "Unknown")")
                            .font(.subheadline)
                            .accessibilityLabel("Date: \(recording?.date.formatted() ?? "Unknown")")
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground).opacity(0.9))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Analyzed audio characteristics
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Analyzed Characteristics:")
                            .font(.headline)
                            .padding(.bottom, 5)
                            .accessibilityLabel("Analyzed Characteristics")
                        
                        Text("🎶 Tempo (BPM): \(String(format: "%.2f", tempo))")
                            .accessibilityLabel("Tempo: \(String(format: "%.2f", tempo)) beats per minute")
                        Text("🎼 Pitch (Hz): \(String(format: "%.2f", pitch))")
                            .accessibilityLabel("Pitch: \(String(format: "%.2f", pitch)) hertz")
                        Text("🔊 Volume (dB): \(String(format: "%.4f", rms))")
                            .accessibilityLabel("RMS: \(String(format: "%.4f", rms)) decibels")
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground).opacity(0.9))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Model prediction results
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Model Predictions:")
                            .font(.headline)
                            .padding(.bottom, 5)
                            .accessibilityLabel("Model Predictions")
                        
                        Text("🚀 Tempo Prediction: \(tempoPrediction)")
                            .foregroundColor(.blue)
                            .accessibilityLabel("Tempo Prediction: \(tempoPrediction)")
                        Text("🎯 Pitch Prediction: \(pitchPrediction)")
                            .foregroundColor(.green)
                            .accessibilityLabel("Pitch Prediction: \(pitchPrediction)")
                        Text("💥 Volume Prediction: \(rmsPrediction)")
                            .foregroundColor(.red)
                            .accessibilityLabel("Volume Prediction: \(rmsPrediction)")
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground).opacity(0.9))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Playback button
                    VStack {
                        Button(action: {
                            if let recording = recording {
                                audioPlayer.play(url: recording.url, recording: recording)
                            } else {
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
                        .accessibilityLabel(audioPlayer.isPlaying ? "Stop playback" : "Play recording")
                        .accessibilityHint("Double tap to play or stop the recording.")
                        
                        // Progress bar if there's duration
                        if audioPlayer.duration > 0 {
                            VStack(spacing: 10) {
                                ProgressView(value: audioPlayer.currentTime, total: audioPlayer.duration)
                                    .accentColor(.blue)
                                    .accessibilityLabel("Playback progress")
                                    .accessibilityValue("\(formatTime(audioPlayer.currentTime)) elapsed out of \(formatTime(audioPlayer.duration))")
                                
                                HStack {
                                    Text(formatTime(audioPlayer.currentTime)) // Elapsed time
                                    Spacer()
                                    Text("-\(formatTime(audioPlayer.duration - audioPlayer.currentTime))") // Remaining time
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .accessibilityLabel("Elapsed time: \(formatTime(audioPlayer.currentTime)), Remaining time: \(formatTime(audioPlayer.duration - audioPlayer.currentTime))")
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                            .background(Color(UIColor.systemBackground).opacity(0.9))
                            .cornerRadius(15)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .alert("No Recording Available", isPresented: $showNoRecordingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("No recording selected to play.")
        }
        .onAppear {
            if let recording = recording {
                audioPlayer.prepare(url: recording.url)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .accessibilityLabel("Done")
                .accessibilityHint("Double tap to close the predictions view.")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Format time (seconds) to mm:ss
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
