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
    
    // Variables para PredictionResultView
    @State private var tempo: Double = 0.0
    @State private var pitch: Double = 0.0
    @State private var rms: Double = 0.0
    @State private var tempoPrediction: String = ""
    @State private var pitchPrediction: String = "Desconocido"
    @State private var rmsPrediction: String = "Desconocido"
    
    @State private var editingRecording: Recording? = nil // Estado para edición
    @State private var showRenameAlert: Bool = false
    @State private var newName: String = "" // Nombre nuevo temporal
    
    @State private var selectedRecordings = Set<UUID>() // Para la selección múltiple
    
    @State private var isEditing: Bool = false // Nueva variable para controlar el modo de edición
    
    @State private var showDeleteConfirmation: Bool = false
    
    @StateObject private var audioPlayer = AudioPlayer()
    
    @State private var selectedRecording: Recording? // Grabación seleccionada
    @State private var showPredictionView: Bool = false // Controla la navegación
    
    let analyzer = AudioAnalyzer()
    let speedModel = SpeedVoiceModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Lista de grabaciones
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
                    }
                    .onDelete(perform: deleteAtOffsets)
                }
                .listStyle(PlainListStyle())
                
                
                if isEditing {
                    HStack {
                        Button(action: {
                            showDeleteConfirmation = true // Mostrar la alerta
                        }) {
                            Label("Eliminar", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.red)
                                .opacity(selectedRecordings.isEmpty ? 0.5 : 1.0) // Cambia la opacidad según el estado
                        }
                        .disabled(selectedRecordings.isEmpty) // Deshabilita si no hay selecciones
                    }
                    .padding()
                    .background(Color(.systemGray6))
                } else { Button(action: {  // Botón de grabación
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
                }
            }
            .navigationTitle("Todas las Grabaciones")
            .toolbar {
                // Botón para activar/desactivar el modo de edición
                Button(action: {
                    isEditing.toggle() // Cambia entre edición y no edición
                }) {
                    Text(isEditing ? "Listo" : "Editar")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPredictionResult) {
                // Mostrar PredictionResultView después de predecir
                PredictionResultView(
                    recording: selectedRecording,
                    tempo: tempo,
                    pitch: pitch,
                    rms: rms,
                    tempoPrediction: tempoPrediction,
                    pitchPrediction: pitchPrediction,
                    rmsPrediction: rmsPrediction
                )
            }
        }
        .onAppear {
            recorder.requestMicrophoneAccess()
        }
        .alert("Renombrar Grabación", isPresented: $showRenameAlert) {
            TextField("Nuevo nombre", text: $newName)
            Button("Guardar", action: saveRenamedRecording)
            Button("Cancelar", role: .cancel) {}
        }
        .alert("Confirmar eliminación", isPresented: $showDeleteConfirmation) {
            Button("Eliminar", role: .destructive) {
                deleteSelectedRecordings() // Borra las grabaciones seleccionadas
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("¿Estás seguro de que deseas eliminar las grabaciones seleccionadas?")
        }
    }
    
    // MARK: - Funciones de grabación
    private func startRecording() {
        recorder.startRecording()
        isRecording = true
    }
    
    private func stopRecording() {
        if let url = recorder.stopRecording() {
            isProcessing = true
            
            // Análisis del audio y predicción
            DispatchQueue.global(qos: .userInitiated).async {
                // Analiza las características del audio
                let analyzedTempo = analyzer.calculateTempo(from: url)
                // Simulación de pitch y rms hasta implementarlos
                let analyzedPitch = 0.0
                let analyzedRMS = 0.0
                
                // Predicción usando SpeedVoiceModel
                let prediction = speedModel.predict(tempoEstimate: analyzedTempo)
                
                DispatchQueue.main.async {
                    // Actualizar valores para PredictionResultView
                    tempo = analyzedTempo
                    pitch = analyzedPitch
                    rms = analyzedRMS
                    tempoPrediction = prediction
                    
                    let baseName = locationManager.currentLocationName // Obtener nombre basado en ubicación
                    let uniqueName = generateUniqueName(baseName: baseName)
                    
                    // Agregar grabación a la lista
                    let newRecording = Recording(
                        id: UUID(),
                        name: uniqueName,
                        date: Date(),
                        duration: recorder.getRecordingDuration(url: url),
                        predictionResult: prediction,
                        url: url
                    )
                    recordings.append(newRecording)
                    recordings.sort { $0.date > $1.date }
                    
                    // Asigna la nueva grabación a selectedRecording antes de mostrar la hoja
                    selectedRecording = newRecording
                    
                    // Mostrar vista de predicción
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
    
    // MARK: - Funciones de Selección
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
    
    
    // Función para generar un nombre único si hay duplicados
    private func generateUniqueName(baseName: String) -> String {
        var name = baseName
        var counter = 1
        let existingNames = recordings.map { $0.name }
        
        // Agregar un sufijo numérico si el nombre ya existe
        while existingNames.contains(name) {
            name = "\(baseName) (\(counter))"
            counter += 1
        }
        return name
    }
}
