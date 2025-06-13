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
    @State private var showFeed = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Image Classification")
                    .font(.title)
                
                if !showFeed {
                    photo
                } else {
                    CameraFeedView(frame: $vm.frame, cameraOn: showFeed)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .frame(maxWidth: .infinity)
                        .frame(height: 500)
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
                        showFeed.toggle()
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
                    .overlay {
                        GeometryReader { proxy in
                            ForEach(vm.detectedObjects) { object in
                                let rectangle = object.boundingBox.convertFromObservation(to: proxy.size)
                                Rectangle()
                                    .path(in: rectangle)
                                    .stroke(Color.green, lineWidth: 2)
                                    .overlay(alignment: .bottom) {
                                        Text(object.label)
                                            .font(.caption2)
                                            .foregroundStyle(.green)
                                            .position(x: rectangle.midX,
                                                      y: rectangle.maxY - 10)
                                    }
                            }
                        }
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
