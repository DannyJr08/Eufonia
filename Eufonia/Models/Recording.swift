//
//  Recording.swift
//  Eufonia
//
//  Created by Juan Daniel Rodriguez Oropeza on 17.12.2024.
//

import Foundation

struct Recording: Identifiable {
    let id: UUID
    var name: String
    let date: Date
    let duration: String
    let predictionResult: String
    let url: URL
}
