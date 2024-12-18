//
//  ContentView.swift
//  Eufonia
//
//  Created by Juan Daniel Rodriguez Oropeza on 10.12.2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var recorder = AudioRecorder()
    @StateObject private var locationManager = LocationManager()
    
    @State private var recordings: [Recording] = []
    @State private var isRecording: Bool = false
    @State private var isProcessing: Bool = false
    @State private var showPredictionResult: Bool = false
    
    // Variables for PredictionResultView
    @State private var tempo: Double = 0.0
    @State private var pitch: Double = 0.0
    @State private var rms: Double = 0.0
    @State private var tempoPrediction: String = "Unknown"
    @State private var pitchPrediction: String = "Unknown"
    @State private var rmsPrediction: String = "Unknown"
    
    @State private var editingRecording: Recording? = nil
    @State private var showRenameAlert: Bool = false
    @State private var newName: String = ""
    
    @State private var selectedRecordings = Set<UUID>()
    @State private var isEditing: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    
    @StateObject private var audioPlayer = AudioPlayer()
    
    @State private var selectedRecording: Recording?
    @State private var showPredictionView: Bool = false
    
    let analyzer = AudioAnalyzer()
    let speedModel = SpeedVoiceModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // List of recordings
                List(selection: $selectedRecordings) {
                    ForEach(recordings) { recording in
                        RecordingRowView(
                            recording: recording,
                            isEditing: isEditing,
                            selectedRecordings: $selectedRecordings,
                            onDelete: { recordingToDelete in
                                deleteRecording(recordingToDelete)
                            },
                            onEdit: { recordingToEdit in
                                startEditing(recordingToEdit)
                            },
                            onSelect: { recordingSelected in
                                toggleSelection(for: recordingSelected)
                            },
                            onTapNonEditing: { recordingTapped in
                                selectedRecording = recordingTapped
                                showPredictionResult = true
                            }
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(recording.name). Duration: \(recording.duration). Tempo: \(recording.predictionResult). Pitch: \(recording.pitch) Hz. Volume: \(recording.volumeClassification).")
                        .accessibilityHint("Double tap to show prediction details.")
                    }
                    .onDelete(perform: deleteAtOffsets)
                }
                .listStyle(PlainListStyle())
                
                if isEditing {
                    HStack {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Label("Delete", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.red)
                                .opacity(selectedRecordings.isEmpty ? 0.5 : 1.0)
                        }
                        .disabled(selectedRecordings.isEmpty)
                        .accessibilityLabel("Delete selected recordings")
                        .accessibilityHint("Deletes the selected recordings from the list.")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                } else if isProcessing {
                    // Show a processing indicator
                    ProgressView("Processing audio...")
                        .padding()
                        .accessibilityLabel("Processing audio")
                        .accessibilityHint("Please wait until the analysis is complete.")
                } else {
                    Button(action: {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    }) {
                        Image(systemName: isRecording ? "stop.circle.fill" : "record.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(isRecording ? .red : .blue)
                    }
                    .padding()
                    .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
                    .accessibilityHint("Double tap to start or stop recording audio.")
                }
            }
            .navigationTitle("All Recordings")
            .toolbar {
                // Button to enable/disable editing mode
                Button(action: {
                    isEditing.toggle()
                }) {
                    Text(isEditing ? "Done" : "Edit")
                }
                .accessibilityLabel(isEditing ? "Done editing" : "Edit recordings")
                .accessibilityHint("Double tap to enter or exit editing mode.")
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPredictionResult) {
                NavigationView {
                    PredictionResultView(
                        recording: selectedRecording,
                        tempo: tempo,
                        pitch: pitch,
                        rms: rms,
                        tempoPrediction: tempoPrediction,
                        pitchPrediction: pitchPrediction,
                        rmsPrediction: rmsPrediction
                    )
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .onAppear {
            recorder.requestMicrophoneAccess()
        }
        .alert("Rename Recording", isPresented: $showRenameAlert) {
            TextField("New name", text: $newName)
            Button("Save", action: saveRenamedRecording)
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete confirmation", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteSelectedRecordings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete the selected recordings?")
        }
    }
    
    // MARK: - Recording functions
    private func startRecording() {
        recorder.startRecording()
        isRecording = true
    }
    
    private func stopRecording() {
        if let url = recorder.stopRecording() {
            isProcessing = true
            
            // Audio analysis and prediction
            DispatchQueue.global(qos: .userInitiated).async {
                let analyzedTempo = analyzer.calculateTempo(from: url)
                let analyzedPitch = analyzer.calculatePitch(from: url)
                let analyzedRMS = analyzer.calculateRMS(from: url)
                
                // Prediction using SpeedVoiceModel
                let prediction = speedModel.predict(tempoEstimate: analyzedTempo)
                
                let pitchModel = PitchVoiceModel()
                let predictionPitch = pitchModel.predict(pitchEstimate: analyzedPitch)
                
                DispatchQueue.main.async {
                    // Update values for PredictionResultView
                    tempo = analyzedTempo
                    pitch = analyzedPitch
                    rms = analyzedRMS
                    tempoPrediction = prediction
                    pitchPrediction = predictionPitch
                    
                    // Classify volume
                    rmsPrediction = classifyVolume(db: rms)
                    
                    let baseName = locationManager.currentLocationName
                    let uniqueName = generateUniqueName(baseName: baseName)
                    
                    let newRecording = Recording(
                        id: UUID(),
                        name: uniqueName,
                        date: Date(),
                        duration: recorder.getRecordingDuration(url: url),
                        predictionResult: tempoPrediction,
                        url: url,
                        pitch: pitchPrediction,
                        volumeClassification: rmsPrediction
                    )
                    recordings.append(newRecording)
                    recordings.sort { $0.date > $1.date }
                    
                    selectedRecording = newRecording
                    
                    showPredictionResult = true
                    isRecording = false
                    isProcessing = false
                }
            }
        }
    }
    
    private func deleteRecording(_ recording: Recording) {
        recordings.removeAll { $0.id == recording.id }
    }
    
    private func deleteAtOffsets(offsets: IndexSet) {
        recordings.remove(atOffsets: offsets)
    }
    
    private func startEditing(_ recording: Recording) {
        editingRecording = recording
        newName = recording.name
        showRenameAlert = true
    }
    
    private func saveRenamedRecording() {
        if let index = recordings.firstIndex(where: { $0.id == editingRecording?.id }) {
            recordings[index].name = newName
        }
    }
    
    private func toggleSelection(for recording: Recording) {
        if selectedRecordings.contains(recording.id) {
            selectedRecordings.remove(recording.id)
        } else {
            selectedRecordings.insert(recording.id)
        }
    }
    
    private func deleteSelectedRecordings() {
        recordings.removeAll { selectedRecordings.contains($0.id) }
        selectedRecordings.removeAll()
    }
    
    private func generateUniqueName(baseName: String) -> String {
        var name = baseName
        var counter = 1
        let existingNames = recordings.map { $0.name }
        while existingNames.contains(name) {
            name = "\(baseName) (\(counter))"
            counter += 1
        }
        return name
    }
    
    func classifyVolume(db: Double) -> String {
        switch db {
        case let x where x < -40:
            return "Low volume"
        case -40...(-20):
            return "Moderate volume"
        default:
            return "High volume"
        }
    }
}
