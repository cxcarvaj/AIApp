//
//  ModelsVM.swift
//  AIApp
//
//  Created by Carlos Xavier Carvajal Villegas on 8/6/25.
//

import SwiftUI
import CoreML
import Vision
import PhotosUI

@Observable @MainActor
final class ModelsVM {
    var image: UIImage?
    var photoPicker: PhotosPickerItem? {
        didSet {
            if let photoPicker {
                photoPicker.loadTransferable(type: Data.self) { result in
                    if case .success(let successResult) = result, let successResult {
                        Task { @MainActor in
                            self.image = UIImage(data: successResult)
                        }
                    }
                }
            }
        }
    }
    
    var selectedModel: Models = .none
    var engine: ModelExecution = .vision
    var observations: [Observations] = []
    
    var errorMsg = ""
    var showAlert = false
    
    
    func arise() {
        do {
            try executeModel(selectedModel, with: engine)
        } catch {
            handleError(error)
        }
    }

    func executeModel(_ model: Models, with engine: ModelExecution) throws {
        let modelExecutor = try createModelExecutor(for: model, engine: engine)
        modelExecutor()
    }

    private func createModelExecutor(for model: Models, engine: ModelExecution) throws -> () -> Void {
        switch (model, engine) {
        case (.anime1, .vision):
            let model = try Anime1()
            return { self.performVisionModel(model: model.model) }
        case (.anime1, .coreml):
            return performModelAnime
        case (.anime1, .ios18):
            return { Task { await self.classifyImages() } }
        case (.vision, .vision):
            let model = try FastViTT8F16()
            return { self.performVisionModel(model: model.model) }
        case (.vision, .coreml):
            return performModelFastViT
        case (.vision, .ios18):
            return { Task { await self.classifyImages() } }
        case (.none, _):
            return {}
        }
    }
    
    private func handleError(_ error: Error) {
        errorMsg = "Error en la predicción: \(error.localizedDescription)"
        showAlert.toggle()
    }
    
    
    func classifyImages() async {
        // Nueva API de iOS 18 y con los modelos pre-cargados de Apple
        do {
            guard let image, let cgImage = image.cgImage else { return }
            var request = ClassifyImageRequest()
            request.cropAndScaleAction = .scaleToFillPlus90CCWRotation
            let results = try await request.perform(on: cgImage, orientation: .right)
            observations = results.map({ result in
                Observations(confidence: result.confidence, label: result.identifier)
            })
        } catch {
            print("Error al clasificar la imagen: \(error)")
            errorMsg = "Error al clasificar la imagen: \(error)"
            showAlert = true
        }
                
    }
    func performVisionModel(model: MLModel) {
        //API antigua que sí permite usar nuestros propios modelos
        guard let image,
              let imageData = image.pngData() else { return }
        do {
            let vnModel = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: vnModel)
            let imageRequest = VNImageRequestHandler(data: imageData, orientation: .right)
            try imageRequest.perform([request])
            
            if let results = request.results {
                observations = results
                    .compactMap { $0 as? VNClassificationObservation }
                    .sorted { $0.confidence > $1.confidence }
                    .map {
                        Observations(confidence: $0.confidence * 100, label: $0.identifier)
                    }
            }
        } catch {
            errorMsg = "Error en la predicción \(error)"
            showAlert.toggle()
        }
    }
    
    func performModelFastViT() {
        guard let image = image?.resizeImage(width: 256, height: 256),
              let cvBuffer = image.pixelBuffer else { return }
        do {
            let model = try FastViTT8F16()
            let prediction = try model.prediction(image: cvBuffer)
            observations = prediction.classLabel_probs
                .sorted { dic1, dic2 in
                    dic1.value > dic2.value
                }
                .map { (key, value) in
                    Observations(confidence: Float(value * 100), label: key)
                }
        } catch {
            errorMsg = "Error en la predicción \(error)"
            showAlert.toggle()
        }
    }
    
    func performModelAnime() {
        guard let image = image?.resizeImage(width: 256, height: 256),
              let cvBuffer = image.pixelBuffer else { return }
        do {
            let model = try Anime1()
            let prediction = try model.prediction(image: cvBuffer)
            observations = prediction.targetProbability
                .sorted { dic1, dic2 in
                    dic1.value > dic2.value
                }
                .map { (key, value) in
                    Observations(confidence: Float(value * 100), label: key)
                }
        } catch {
            errorMsg = "Error en la predicción \(error)"
            showAlert.toggle()
        }
    }
}
