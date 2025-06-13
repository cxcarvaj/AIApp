//
//  VisionLibraryView.swift
//  AIApp
//
//  Created by Carlos Xavier Carvajal Villegas on 8/6/25.
//

import SwiftUI
import PhotosUI

struct VisionLibraryView: View {
    @State private var vm = ModelsVM()
    @State private var showCamera = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Image Classification")
                    .font(.title)
                
                if !vm.showFeed {
                    photo
                } else {
                    CameraFeedView(frame: $vm.frame,
                                   cameraOn: vm.showFeed,
                                   position: vm.cameraPosition)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .frame(maxWidth: .infinity)
                        .frame(width: 230, height: 400)
                        .overlay {
                            Rectangle()
                                .stroke(lineWidth: 5)
                                .fill(.white)
                        }
                        .applyIf(vm.selectedModel != .hands || vm.selectedModel != .fullFaces) { content in
                            content.rectanglesDetected(objects: $vm.detectedObjects,
                                                       mirror: vm.cameraPosition == .front)
                        }
                        .applyIf(vm.selectedModel == .fullFaces) { content in
                            content.elementsDetected(elements: vm.detectedObjects,
                                                     mirrored: vm.cameraPosition == .front)
                        }
                        .applyIf(vm.selectedModel == .hands) { content in
                            content.handDetected(hands: vm.detectedObjects,
                                                 mirrored: vm.cameraPosition == .front)
                        }
                    
                    Picker(selection: $vm.cameraPosition) {
                        ForEach(CameraPosition.allCases) { position in
                            Text(position.rawValue)
                                .tag(position)
                        }
                    } label: {
                        Text("Select camera")
                    }
                    .pickerStyle(.segmented)
                }
                
                HStack {
                    PhotosPicker(selection: $vm.photoPicker) {
                        Image(systemName: "photo")
                    }
                    Button {
                        showCamera.toggle()
                    } label: {
                        Image(systemName: "camera")
                    }
                    Button {
                        vm.showFeed.toggle()
                    } label: {
                        Image(systemName: "video")
                    }
                }
                .symbolVariant(.fill)
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .font(.title2)
                
                HStack {
                    Text("Pick a model")
                    Picker(selection: $vm.selectedModel) {
                        ForEach(Models.allCases) { model in
                            Text(model.rawValue)
                                .tag(model)
                        }
                    } label: {
                        Text("Select a model")
                    }
                }
                .padding(.top)
                Picker(selection: $vm.engine) {
                    ForEach(ModelExecution.allCases) { model in
                        Text(model.rawValue)
                            .tag(model)
                    }
                } label: {
                    Text("Elige el motor")
                }
                .pickerStyle(.segmented)
                
                Button {
                    vm.arise()
                } label: {
                    Text("Arise")
                }
                .buttonStyle(.bordered)
                .disabled(vm.selectedModel == .none)
                .padding(.top)
                
                if vm.observations.count > 0 {
                    Text("Observations")
                        .font(.title2)
                    ForEach(vm.observations) { observation in
                        HStack {
                            Text(observation.label)
                                .font(.headline)
                            Spacer()
                            Text("\(observation.confidence)%")
                        }
                    }
                }
            }
            .safeAreaPadding()
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView(photo: $vm.image)
            }
        }
    }
    
    var photo: some View {
        VStack {
            if let image = vm.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .rectanglesDetected(objects: $vm.detectedObjects,
                                        mirror: false)
                    .applyIf(vm.selectedModel == .animals ||
                             vm.selectedModel == .hands) { content in
                        content.points18Detected(animals:
                                                    vm.detectedElements18)
                    }
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    VisionLibraryView()
}
