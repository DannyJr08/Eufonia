//
//  SpeedVoiceModel.swift
//  Eufonia
//
//  Created by Juan Daniel Rodriguez Oropeza on 10.12.2024.
//

import CoreML

import CoreML

class SpeedVoiceModel {
    private let model: SpeedVoiceTabularRegressor
    
    // MARK: - Inicialización del modelo
    init() {
        do {
            // Inicializar el modelo Core ML
            model = try SpeedVoiceTabularRegressor(configuration: MLModelConfiguration())
        } catch {
            fatalError("No se pudo cargar el modelo Core ML: \(error)")
        }
    }
    
    // MARK: - Predicción
    func predict(tempoEstimate: Double) -> String {
        do {
            // Normalización si es necesario
            let normalizedTempo = tempoEstimate / 250.0 // Ajusta según el rango usado en el entrenamiento
            
            // Crear entrada para el modelo
            let input = SpeedVoiceTabularRegressorInput(tempo_estimate: normalizedTempo)
            
            // Obtener la predicción del modelo
            let output = try model.prediction(input: input)
            
            // Redondear la etiqueta predicha
            let roundedLabel = Int(round(output.label))
            
            // Imprime la etiqueta predicha
            print("Etiqueta predicha por el modelo: \(output.label)")
            
            // Depuración: Imprimir el valor redondeado
            print("Etiqueta predicha (redondeada): \(roundedLabel)")
            
            // Convertir la etiqueta en Double para hacer el switch
            switch roundedLabel {
            case 0:
                return "Hablaste lento"
            case 1:
                return "Hablaste a una velocidad normal"
            case 2:
                return "Hablaste rápido"
            default:
                return "No se pudo determinar la velocidad"
            }
        } catch {
            print("Error durante la predicción: \(error)")
            return "Error en la predicción"
        }
    }
}
