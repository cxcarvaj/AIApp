//
//  CameraFeed.swift
//  AIApp
//
//  Created by Carlos Xavier Carvajal Villegas on 11/6/25.
//


import SwiftUI
@preconcurrency import AVFoundation

extension CVPixelBuffer: @retroactive @unchecked Sendable {}

struct CameraFeedView: UIViewControllerRepresentable {
    typealias UIViewControllerType = CameraFeedViewController
    
    @Binding var frame: CVPixelBuffer?
    let cameraOn: Bool
    let position: CameraPosition
    
    func makeUIViewController(context: Context) -> CameraFeedViewController {
        let camera = CameraFeedViewController(frame: $frame)
        do {
            try camera.initCapture()
        } catch {
            print("Error en la inicialización")
        }
        return camera
    }
    
    func updateUIViewController(_ uiViewController: CameraFeedViewController, context: Context) {
        if cameraOn {
            uiViewController.startCapture()
        } else {
            uiViewController.stopCapture()
        }
        uiViewController.switchCamera(to: position)
    }
}

final class CameraFeedViewController: UIViewController {
    @Binding var frame: CVPixelBuffer?
    
    var device: AVCaptureDevice!
    var previewLayer = AVCaptureVideoPreviewLayer()
    nonisolated let session = AVCaptureSession()
    
    var position: CameraPosition = .back
    
    private let queue = DispatchQueue.global(qos: .default)
    
    init(frame: Binding<CVPixelBuffer?>) {
        _frame = frame
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        _frame = .constant(nil)
        super.init(coder: coder)
    }
    
    func initCapture() throws {
//        guard !session.isRunning,
//        let capture = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
//        self.device = capture
//        session.sessionPreset = .high
//        let input = try AVCaptureDeviceInput(device: device)
//        session.addInput(input)
        
        guard !session.isRunning else { return }
        session.sessionPreset = .hd1920x1080
        try configureCamera(for: position)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: queue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        session.addOutput(output)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(previewLayer)
    }
    
    nonisolated func configureCamera(for position: CameraPosition) throws {
        session.beginConfiguration()
        session.inputs.forEach { input in
            session.removeInput(input)
        }
        
        let avPosition: AVCaptureDevice.Position = (position == .front) ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: avPosition) else {
            session.commitConfiguration()
            print("No se ha inicializado la cámara")
            return
        }
        Task { @MainActor in
            self.device = device
        }
        let newInput = try AVCaptureDeviceInput(device: device)
        session.addInput(newInput)
        session.commitConfiguration()
    }
    
    func switchCamera(to position: CameraPosition) {
        guard self.position != position else { return }
        self.position = position
        
        queue.async {
            do {
                try self.configureCamera(for: position)
            } catch {
                print("Error \(error)")
            }
        }
    }
    
    func startCapture() {
        queue.async {
            self.session.startRunning()
            DispatchQueue.main.async {
                self.previewLayer.isHidden = false
            }
        }
    }
    
    func stopCapture() {
        queue.async {
            self.session.stopRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        view.layer.sublayers?.first?.frame = view.bounds
    }
}

extension CameraFeedViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        Task { @MainActor in
            self.frame = buffer
        }
    }
}
