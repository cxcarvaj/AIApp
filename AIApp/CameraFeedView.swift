//
//  CameraFeedView.swift
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
    }
}

final class CameraFeedViewController: UIViewController {
    @Binding var frame: CVPixelBuffer?
    
    var device: AVCaptureDevice!
    var previewLayer = AVCaptureVideoPreviewLayer()
    nonisolated let session = AVCaptureSession()
    
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
        guard !session.isRunning,
        let capture = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        self.device = capture
        session.sessionPreset = .high
        let input = try AVCaptureDeviceInput(device: device)
        session.addInput(input)
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: queue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        session.addOutput(output)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(previewLayer)
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
