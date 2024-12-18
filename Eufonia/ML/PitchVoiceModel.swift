//
//  PitchVoiceModel.swift
//  Eufonia
//
//  Created by Juan Daniel Rodriguez Oropeza on 18.12.2024.
//

import CoreML

class PitchVoiceModel {
    private let model: PitchVoiceTabularRegressor
    
    // MARK: - Inicialización del modelo
    init() {
        do {
            model = try PitchVoiceTabularRegressor(configuration: MLModelConfiguration())
        } catch {
            fatalError("No se pudo cargar el modelo Core ML: \(error)")
        }
    }
    
    // MARK: - Predicción
    func predict(pitchEstimate: Double) -> String {
        do {
            // Normalización si es necesario
            let normalizedPitch = pitchEstimate / 2500.0 // Ajusta según el rango usado en el entrenamiento
            
            // Crear entrada para el modelo
            let input = PitchVoiceTabularRegressorInput(pitch_mean: normalizedPitch)
            
            // Obtener la predicción
            let output = try model.prediction(input: input)
            
            // Redondear la etiqueta predicha
            let roundedLabel = Int(round(output.label))
            
            // Retornar la predicción con etiquetas
            switch roundedLabel {
            case 0:
                return "Low tone"
            case 1:
                return "Medium tone"
            case 2:
                return "High tone"
            default:
                return "Tone could not be determined"
            }
        } catch {
            print("Error durante la predicción: \(error)")
            return "Error during prediction"
        }
    }
}
