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
    let dadosModel = try? Dados().model
    let yolo = try? YOLOv3Tiny(configuration: MLModelConfiguration()).model
    
    var frame: CVPixelBuffer? {
        didSet {
            if showFeed, let frame {
                switch selectedModel {
                case .yolo:
                    performVisionObjectModelRealtime(model: yolo, buffer: frame)
                case .dados:
                    performVisionObjectModelRealtime(model: dadosModel, buffer: frame)
                case .faces:
                    performFaceDetection(buffer: frame)
                case .fullFaces:
                    performFullFaceDetection(buffer: frame)
                case .hands:
                    performHandDetection(buffer: frame)
                default:()
                }
            }
        }
    }
    
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
    
    var showFeed = false
    var selectedModel: Models = .none
    var engine: ModelExecution = .vision
    var cameraPosition: CameraPosition = .back

    var observations: [Observations] = []
    var detectedObjects: [DetectedObjects] = []
    var detectedElements18: [DetectedElements18] = []
    
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
            return { Task { await self.classifyObjects() } }
            
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
            

        case (.faces, .vision):
            return {
                if let buffer = self.image?.pixelBuffer {
                    self.performFaceDetection(buffer: buffer)
                }
            }
        case (.faces, .coreml):
            return {}
        case (.faces, .ios18):
            return { Task { await self.classifyImages() } }
            
        case (.fullFaces, .vision):
            return {
                if let buffer = self.image?.pixelBuffer {
                    self.performFullFaceDetection(buffer: buffer)
                }
            }
        case (.fullFaces, .coreml):
            return {}
        case (.fullFaces, .ios18):
            return { Task { await self.classifyImages() } }
            
        case (.hands, .vision):
            return {
                if let buffer = self.image?.pixelBuffer {
                    self.performHandDetection(buffer: buffer)
                }
            }
        case (.hands, .coreml):
            return {}
        case (.hands, .ios18):
            return { Task { await self.classifyImages() } }
            
        case (.animals, .vision):
            return {}
        case (.animals, .coreml):
            return {}
        case (.animals, .ios18):
            return { Task { await self.findAnimals() } }

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
            let model = try FastViTT8F16()
            let container = try CoreMLModelContainer(model: model.model)
            var request = CoreMLRequest(model: container)
            request.cropAndScaleAction = .centerCrop
            let results = try await request.perform(on: cgImage, orientation: .right)
            observations = results.compactMap {
                $0 as? ClassificationObservation
            }.filter {
                $0.confidence > 0.1
            }.sorted {
                $0.confidence > $1.confidence
            }.map { result in
                Observations(confidence: Double(result.confidence) * 100, label: result.identifier)
            }
        } catch {
            errorMsg = "Error en la predicción \(error)"
            showAlert.toggle()
        }
    }
    
    func performFaceDetection(buffer: CVPixelBuffer) {
        do {
            let request = VNDetectFaceRectanglesRequest()
            let imageRequest = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .right)
            try imageRequest.perform([request])
            guard let results = request.results else { return }
            var num = 0
            detectedObjects = results.map { observation in
                num += 1
                return DetectedObjects(label: "Cara \(num)",
                                       confidence: 1.0,
                                       boundingBox: observation.boundingBox)
            }
        } catch {
            errorMsg = "Error en la predicción \(error)"
            showAlert.toggle()
        }
    }
    
    func performFullFaceDetection(buffer: CVPixelBuffer) {
        do {
            let request = VNDetectFaceLandmarksRequest()
            let imageRequest = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .right)
            try imageRequest.perform([request])
            guard let results = request.results else { return }
            var num = 0
            detectedObjects = results.map { observation in
                var elements: [DetectedElements] = []
                if let lm = observation.landmarks?.faceContour {
                    elements.append(DetectedElements(label: "Face Contour",
                                                     points: lm.normalizedPoints))
                }
                if let lm = observation.landmarks?.leftEye {
                    elements.append(DetectedElements(label: "Left Eye",
                                                     points: lm.normalizedPoints))
                }
                if let lm = observation.landmarks?.rightEye {
                    elements.append(DetectedElements(label: "Right Eye",
                                                     points: lm.normalizedPoints))
                }
                if let lm = observation.landmarks?.leftEyebrow {
                    elements.append(DetectedElements(label: "Left Eyebrow",
                                                     points: lm.normalizedPoints))
                }
                if let lm = observation.landmarks?.rightEyebrow {
                    elements.append(DetectedElements(label: "Right Eyebrow",
                                                     points: lm.normalizedPoints))
                }
                if let lm = observation.landmarks?.nose {
                    elements.append(DetectedElements(label: "Nose",
                                                     points: lm.normalizedPoints))
                }
                if let lm = observation.landmarks?.noseCrest {
                    elements.append(DetectedElements(label: "Nose Crest",
                                                     points: lm.normalizedPoints))
                }
                if let lm = observation.landmarks?.outerLips {
                    elements.append(DetectedElements(label: "Outer Lips",
                                                     points: lm.normalizedPoints))
                }
                if let lm = observation.landmarks?.innerLips {
                    elements.append(DetectedElements(label: "Inner Lips",
                                                     points: lm.normalizedPoints))
                }
                if let lm = observation.landmarks?.leftPupil {
                    elements.append(DetectedElements(label: "Left Pupil",
                                                     points: lm.normalizedPoints))
                }
                if let lm = observation.landmarks?.rightPupil {
                    elements.append(DetectedElements(label: "Right Pupil",
                                                     points: lm.normalizedPoints))
                }
                if let lm = observation.landmarks?.medianLine {
                    elements.append(DetectedElements(label: "Median Line",
                                                     points: lm.normalizedPoints))
                }
                num += 1
                return DetectedObjects(label: "Cara \(num)",
                                       confidence: 1.0,
                                       boundingBox: observation.boundingBox,
                                       elements: elements)
            }
        } catch {
            errorMsg = "Error en la predicción \(error)"
            showAlert.toggle()
        }
    }
    
    func performHandDetection(buffer: CVPixelBuffer) {
        do {
            let request = VNDetectHumanHandPoseRequest()
            let imageRequest = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .right)
            try imageRequest.perform([request])
            guard let results = request.results,
                  let hand = results.first else { return }
            let detection = try PiedraPapelTijera(configuration: MLModelConfiguration())
            let prediction = try detection.prediction(poses: hand.keypointsMultiArray())
            observations = prediction.labelProbabilities
                .sorted { d1, d2 in
                    d1.value > d2.value
                }
                .map { (key, value) in
                    Observations(confidence: value * 100, label: key)
                }
            var num = 0
            detectedObjects = try results.map { observation in
                var elements: [DetectedElements] = []
                let index = try observation.recognizedPoints(.indexFinger)
                elements.append(DetectedElements(label: "Index",
                                                 points: index.map(\.value.location)))
                let little = try observation.recognizedPoints(.littleFinger)
                elements.append(DetectedElements(label: "Little",
                                                 points: little.map(\.value.location)))
                let middle = try observation.recognizedPoints(.middleFinger)
                elements.append(DetectedElements(label: "Middle",
                                                 points: middle.map(\.value.location)))
                let ring = try observation.recognizedPoints(.ringFinger)
                elements.append(DetectedElements(label: "Ring",
                                                 points: ring.map(\.value.location)))
                let thumb = try observation.recognizedPoints(.thumb)
                elements.append(DetectedElements(label: "Thumb",
                                                 points: thumb.map(\.value.location)))
                let wrist = try observation.recognizedPoint(.wrist)
                elements.append(DetectedElements(label: "Wrist", points: [wrist.location]))
                num += 1
                return DetectedObjects(label: "Cara \(num)",
                                       confidence: 1.0,
                                       boundingBox: CGRect(),
                                       elements: elements)
            }
        } catch {
            errorMsg = "Error en la predicción \(error)"
            showAlert.toggle()
        }
    }
    
    func findAnimals() async {
        do {
            guard let image, let cgImage = image.cgImage else { return }
            let request = DetectAnimalBodyPoseRequest()
            let observations = try await request.perform(on: cgImage,
                                                         orientation: .right)
            detectedElements18 = observations.compactMap { obs in
                let points = obs.allJoints()
                    .values
                    .filter { $0.confidence > 0.1 }
                    .map(\.location)
                
                return DetectedElements18(label: "Animal",
                                          points: points)
            }
        } catch {
            errorMsg = "Error en la predicción \(error)"
            showAlert.toggle()
        }
    }
    
    func findHands() async {
        do {
            guard let image, let cgImage = image.cgImage else { return }
            let request = DetectHumanHandPoseRequest()
            let observations = try await request.perform(on: cgImage)
            detectedElements18 = observations.compactMap { obs in
                let points = obs.allJoints()
                    .values
                    .filter { $0.confidence > 0.1 }
                    .map(\.location)
                
                return DetectedElements18(label: "Mano",
                                          points: points)
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
            let imageRequest = VNImageRequestHandler(data: imageData)
            try imageRequest.perform([request])
            
            if let results = request.results {
                observations = results
                    .compactMap { $0 as? VNClassificationObservation }
                    .sorted { $0.confidence > $1.confidence }
                    .map {
                        Observations(confidence: Double($0.confidence) * 100, label: $0.identifier)
                    }
                print(observations)
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
            detectedObjects.removeAll(keepingCapacity: true)
            let vnModel = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: vnModel)
            let imageRequest = VNImageRequestHandler(data: imageData)
            try imageRequest.perform([request])
            
            calculateBounds(results: request.results)
        } catch {
            errorMsg = "Error en la predicción \(error)"
            showAlert.toggle()
        }
    }
    
    func performVisionObjectModelRealtime(model: MLModel?,
                                          buffer: CVPixelBuffer) {
        do {
            guard let model else { return }
            let vnModel = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: vnModel)
            let imageRequest = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .right)
            try imageRequest.perform([request])
            
            calculateBounds(results: request.results)
        } catch {
            errorMsg = "Error en la predicción \(error)"
            showAlert.toggle()
        }
    }
    
    func calculateBounds(results: [VNObservation]?) {
        if let results {
            detectedObjects = results
                .compactMap { $0 as? VNRecognizedObjectObservation }
                .compactMap { observ in
                    let objects = observ.labels.sorted {
                        $0.confidence > $1.confidence
                    }
                    return if let object = objects.first {
                        DetectedObjects(label: object.identifier,
                                        confidence: Double(object.confidence),
                                        boundingBox: observ.boundingBox)
                    } else {
                        nil
                    }
                }
            
        }
    }
    
    
    func performModelFastViT() {
        guard let image = image?.resizeImage(width: 256, height: 256),
              let cvBuffer = image.pixelBuffer else { return }
        do {
            let model = try FastViTT8F16()
            let prediction = try model.prediction(image: cvBuffer)
            observations = prediction.classLabel_probs
                .sorted { d1, d2 in
                    d1.value > d2.value
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
                .sorted { d1, d2 in
                    d1.value > d2.value
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
                .sorted { d1, d2 in
                    d1.value > d2.value
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
