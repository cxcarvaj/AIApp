//
//  Models.swift
//  AIApp
//
//  Created by Carlos Xavier Carvajal Villegas on 11/6/25.
//

import SwiftUI
import Vision

//No se puede llamar `Observation` porque es palabra registrada del sistema
struct Observations: Identifiable {
    let id = UUID()
    let confidence: Double
    let label: String
}

struct DetectedObjects: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Double
    let boundingBox: CGRect
    var elements: [DetectedElements] = []
}

struct DetectedElements: Identifiable {
    let id = UUID()
    let label: String
    let points: [CGPoint]
}

struct DetectedElements18: Identifiable {
    let id = UUID()
    let label: String
    let points: [NormalizedPoint]
}

enum CameraPosition: String, Identifiable, CaseIterable {
    case front = "Front"
    case back = "Back"
    
    var id: Self { self }
}
