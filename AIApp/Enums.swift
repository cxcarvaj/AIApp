//
//  Enums.swift
//  AIApp
//
//  Created by Carlos Xavier Carvajal Villegas on 8/6/25.
//

import Foundation

enum Models: String, Identifiable, CaseIterable {
    case anime1 = "Anime 1"
    case vision = "Vision"
    case none = "None"
    
    var id: Self { self }
}

enum ModelExecution: String, Identifiable, CaseIterable {
    case vision = "VisionKit"
    case coreml = "CoreML"
    case ios18 = "iOS 18"
    
    var id: Self { self }
}

//No se puede llamar `Observation` porque es palabra registrada del sistema
struct Observations: Identifiable {
    let id = UUID()
    let confidence: Float
    let label: String
}
