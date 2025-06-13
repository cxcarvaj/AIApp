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
    var frame: CVPixelBuffer?
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
    var detectedObjects: [DetectedObjects] = []
    
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
            
        case (.superHeroe, .vision):
            let model = try SuperHeroes()
            return { self.performVisionModel(model: model.model) }
        case (.superHeroe, .coreml):
            return performModelSuperHeroe
        case (.superHeroe, .ios18):
            return { Task { await self.classifyImages() } }

        case (.vision, .vision):
            let model = try FastViTT8F16()
            return { self.performVisionModel(model: model.model) }
        case (.vision, .coreml):
            return performModelFastViT
        case (.vision, .ios18):
            return { Task { await self.classifyImages() } }
            
        case (.yolo, .vision):
            let model = try YOLOv3Tiny(configuration: MLModelConfiguration())
            return { self.performVisionObjectModel(model: model.model) }
        case (.yolo, .coreml):
            return performModelYolov3
        case (.yolo, .ios18):
            return { Task { await self.classifyImages() } }

        case (.dados, .vision):
            let model = try Dados()
            return { self.performVisionObjectModel(model: model.model) }
        case (.dados, .coreml):
            return performModelYolov3
        case (.dados, .ios18):
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
                Observations(confidence: Double(result.confidence) * 100, label: result.identifier)
            })
        } catch {
            print("Error al clasificar la imagen: \(error)")
            errorMsg = "Error al clasificar la imagen: \(error)"
            showAlert = true
        }
                
    }
    
    func classifyObjects() async {
        do {
            guard let image, let cgImage = image.cgImage else { return }
            var request = ClassifyImageRequest()
            request.cropAndScaleAction = .centerCrop
            let results = try await request.perform(on: cgImage, orientation: .right)
            observations = results.map { result in
                Observations(confidence: Double(result.confidence) * 100, label: result.identifier)
            }
        } catch {
            errorMsg = "Error en la predicción \(error)"
            showAlert.toggle()
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
                        Observations(confidence: Double($0.confidence) * 100, label: $0.identifier)
                    }
            }
        } catch {
            errorMsg = "Error en la predicción \(error)"
            showAlert.toggle()
        }
    }
    
    func performVisionObjectModel(model: MLModel) {
        guard let image,
              let resize = image.resizeImage(width: 299, height: 299),
              let imageData = resize.pngData() else { return }
        
        do {
            detectedObjects.removeAll()
            let vnModel = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: vnModel)
            let imageRequest = VNImageRequestHandler(data: imageData)
            try imageRequest.perform([request])
            
            if let results = request.results {
                detectedObjects = results
                    .compactMap { $0 as? VNRecognizedObjectObservation }
                    .compactMap { objObservation in
                        let objects = objObservation.labels.sorted {
                            $0.confidence > $1.confidence
                        }
                        return if let object = objects.first {
                            DetectedObjects(label: object.identifier,
                                            confidence: Double(object.confidence),
                                            boundingBox: objObservation.boundingBox)
                        } else {
                            nil
                        }
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
                    Observations(confidence: value * 100, label: key)
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
                    Observations(confidence: value * 100, label: key)
                }
        } catch {
            errorMsg = "Error en la predicción \(error)"
            showAlert.toggle()
        }
    }
    
    func performModelSuperHeroe() {
         guard let image = image?.resizeImage(width: 360, height: 360),
               let cvBuffer = image.pixelBuffer else { return }
         do {
             let model = try SuperHeroes()
             let prediction = try model.prediction(image: cvBuffer)
             observations = prediction.targetProbability
                 .sorted { dic1, dic2 in
                     dic1.value > dic2.value
                 }
                 .map { (key, value) in
                     Observations(confidence: value * 100, label: key)
                 }
             print(observations)
         } catch {
             errorMsg = "Error en la predicción \(error)"
             showAlert.toggle()
         }
     }
    
    func performModelYolov3() {
        guard let image = image?.resizeImage(width: 416, height: 416),
              let cvBuffer = image.pixelBuffer else { return }
        do {
            let model = try YOLOv3Tiny(configuration: MLModelConfiguration())
            let _ = try model.prediction(image: cvBuffer,
                                                  iouThreshold: nil,
                                                  confidenceThreshold: 0.60)
            // TO DO
        } catch {
            errorMsg = "Error en la predicción \(error)"
            showAlert.toggle()
        }
    }
}
