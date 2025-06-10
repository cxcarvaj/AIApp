//
//  CameraPickerView.swift
//  AIApp
//
//  Created by Carlos Xavier Carvajal Villegas on 9/6/25.
//


import SwiftUI

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var photo: UIImage?
    
    //Esto indica cual es la clase de UIKit que usaremos en SwiftUI (IMPORTANTE!!!)
    typealias UIViewControllerType = UIImagePickerController
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        @Binding var photo: UIImage?
        
        init(photo: Binding<UIImage?>) {
            self._photo = photo
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            photo = info[.editedImage] as? UIImage
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(photo: $photo)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let camera = UIImagePickerController()
        camera.sourceType = .camera
        camera.cameraCaptureMode = .photo
        camera.allowsEditing = true
        camera.delegate = context.coordinator
        return camera
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
