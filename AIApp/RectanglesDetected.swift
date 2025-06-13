//
//  RectanglesDetected.swift
//  AIApp
//
//  Created by Carlos Xavier Carvajal Villegas on 13/6/25.
//

import SwiftUI

struct RectanglesDetected: ViewModifier {
    @Binding var detectedObjects: [DetectedObjects]
    let mirror: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    ForEach(detectedObjects) { object in
                        let rectangle = !mirror ? object.boundingBox.convertFromObservation(to: proxy.size) :
                        object.boundingBox.convertFromObservation(to: proxy.size).mirrored(in: proxy.size.width)
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
    }
}

extension View {
    func rectanglesDetected(objects: Binding<[DetectedObjects]>, mirror: Bool) -> some View {
        modifier(RectanglesDetected(detectedObjects: objects, mirror: mirror))
    }
}
