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
    case superHeroe = "Súper Héroe"
    case yolo = "Yolov3"
    case dados = "Dados"
    case faces = "Faces"
    case fullFaces = "Full Faces"
    case hands = "Hands"
    case none = "None"
    
    var id: Self { self }
}

enum ModelExecution: String, Identifiable, CaseIterable {
    case vision = "VisionKit"
    case coreml = "CoreML"
    case ios18 = "iOS 18"
    
    var id: Self { self }
}
