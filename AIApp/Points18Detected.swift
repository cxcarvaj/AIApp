//
//  Points18Detected.swift
//  AIApp
//
//  Created by Carlos Xavier Carvajal Villegas on 13/6/25.
//

import SwiftUI

struct Points18Detected: ViewModifier {
    let animals: [DetectedElements18]
    
    func body(content: Content) -> some View {
        content
            .overlay {
                ForEach(animals) { animal in
                    ForEach(animal.points, id: \.self) { point in
                        GeometryReader { proxy in
                            Canvas { context, _ in
                                let pt = point.toImageCoordinates(from: .fullImage,
                                                                  imageSize: proxy.size,
                                                                  origin: .upperLeft)
                                let dot = CGRect(x: pt.x - 4,
                                                 y: pt.y - 4,
                                                 width: 8,
                                                 height: 8)
                                context.fill(Path(ellipseIn: dot),
                                             with: .color(.green))
                            }
                        }
                    }
                }
            }
    }
}

extension View {
    func points18Detected(animals: [DetectedElements18]) -> some View {
        modifier(Points18Detected(animals: animals))
    }
}
