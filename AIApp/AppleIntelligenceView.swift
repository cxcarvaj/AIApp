//
//  AppleIntelligenceView.swift
//  AIApp
//
//  Created by Carlos Xavier Carvajal Villegas on 13/6/25.
//

import SwiftUI
import Translation
import ImagePlayground

struct AppleIntelligenceView: View {
    @State private var vm = AppleIntelligenceVM()
    @State private var showTranslate = false
    @State private var showPlayground = false
    @Environment(\.supportsImagePlayground) var imagePlayground
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    TextEditor(text: $vm.text)
                        .writingToolsBehavior(.complete)
                        .scrollContentBackground(.hidden)
                        .frame(width: 500, height: 300)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    HStack {
                        Button {
                            vm.speak()
                        } label: {
                            Image(systemName: "play")
                        }
                        .buttonBorderShape(.circle)
                        .buttonStyle(.bordered)
                        .disabled(vm.isTalking)
                        
                        Button {
                            vm.dontSpeak()
                        } label: {
                            Image(systemName: "stop")
                        }
                        .buttonBorderShape(.circle)
                        .buttonStyle(.bordered)
                        .disabled(!vm.isTalking)
                        
                        Button {
                            vm.startRecording()
                        } label: {
                            Image(systemName: "record.circle")
                        }
                        .buttonBorderShape(.circle)
                        .buttonStyle(.bordered)
                        .disabled(vm.isRecording)
                        .padding(.leading)
                        
                        Button {
                            vm.stopRecording()
                        } label: {
                            Image(systemName: "stop.circle")
                        }
                        .buttonBorderShape(.circle)
                        .buttonStyle(.bordered)
                        .disabled(!vm.isRecording)
                    }
                }
                Spacer()
                VStack {
                    Button {
                        vm.makeTranslation()
                    } label: {
                        Text("Traducir")
                    }
                    Button {
                        showTranslate.toggle()
                    } label: {
                        Text("Traducción")
                    }
                    .translationPresentation(isPresented: $showTranslate, text: vm.text)
                }
                Spacer()
                Text(vm.translation)
                    .frame(width: 500, height: 300)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Spacer()
            if imagePlayground {
                TextField("Indique su prompt", text: $vm.prompt, axis: .vertical)
                    .lineLimit(3)
                    .frame(width: 300)
                if let url = vm.imageURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        Image(systemName: "photo")
                    }
                    .frame(width: 300, height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button {
                    showPlayground.toggle()
                } label: {
                    Text("Invocar Playground")
                }
                .imagePlaygroundSheet(isPresented: $showPlayground, concept: vm.prompt) { url in
                    vm.imageURL = url
                }
            } else {
                ContentUnavailableView("Image Playground no soportado", systemImage: "exclamationmark.triangle.fill", description: Text("Este dispositivo no soporta o no tiene activado Image Playground."))
            }
        }
        .buttonStyle(.bordered)
        .safeAreaPadding()
        .translationTask(vm.configuration) { session in
            Task { @MainActor in
                vm.isGenerating = true
                let response = try? await session.translate(vm.text)
                vm.isGenerating = false
                vm.translation = response?.targetText ?? ""
            }
        }
        .onAppear {
            vm.configureAudioSession()
        }
    }
}

#Preview {
    AppleIntelligenceView()
}
