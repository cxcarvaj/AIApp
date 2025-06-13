//
//  ElementsDetected.swift
//  AIApp
//
//  Created by Carlos Xavier Carvajal Villegas on 13/6/25.
//

import SwiftUI

struct ElementsDetected: ViewModifier {
    let elements: [DetectedObjects]
    var mirrored: Bool = false
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    ForEach(elements) { element in
                        let bb = mirrored ? element.boundingBox
                            .convertFromObservation(to: proxy.size).mirrored(in: proxy.size.width) : element.boundingBox
                            .convertFromObservation(to: proxy.size)
                    
                        ForEach(element.elements) { ele in
                            Canvas { context, _ in
                                var path = Path()
                                path.addLines(ele.points.map {
                                    if mirrored {
                                        $0.convertFromObservation(to: bb.size)
                                            .mirrored(in: bb.size.width) + bb.origin
                                    } else {
                                        $0.convertFromObservation(to: bb.size) + bb.origin
                                    }
                                })
                                path.closeSubpath()
                                context.stroke(path,
                                               with: .color(.green),
                                               lineWidth: 2)
                            }
                        }
                    }
                }
            }
    }
}

extension View {
    func elementsDetected(elements: [DetectedObjects], mirrored: Bool) -> some View {
        modifier(ElementsDetected(elements: elements, mirrored: mirrored))
    }
}
