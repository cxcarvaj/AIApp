//
//  HandDetected.swift
//  AIApp
//
//  Created by Carlos Xavier Carvajal Villegas on 13/6/25.
//

import SwiftUI

struct HandDetected: ViewModifier {
    let hands: [DetectedObjects]
    var mirrored: Bool = false
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    ForEach(hands) { hand in
                        let wrist = hand.elements.first(where: { $0.label == "Wrist" })?.points.first
                        
                        ForEach(hand.elements.filter { $0.label != "Wrist" }) { finger in
                            Canvas { context, _ in
                                let ordered = finger.points.sorted { p1, p2 in
                                    let d1 = hypot(p1.x - (wrist?.x ?? 0), p1.y - (wrist?.y ?? 0))
                                    let d2 = hypot(p2.x - (wrist?.x ?? 0), p2.y - (wrist?.y ?? 0))
                                    return d1 < d2
                                }
                                
                                var path = Path()
                                
                                let wristPoint = mirrored
                                ? (wrist ?? .zero).convertFromObservation(to: proxy.size)
                                    .mirrored(in: proxy.size.width)
                                : (wrist ?? .zero).convertFromObservation(to: proxy.size)
                                path.move(to: wristPoint)
                                
                                ordered.forEach { joint in
                                    let jointPoint = mirrored
                                    ? joint.convertFromObservation(to: proxy.size)
                                        .mirrored(in: proxy.size.width)
                                    : joint.convertFromObservation(to: proxy.size)
                                    path.addLine(to: jointPoint)
                                }
                                
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
    func handDetected(hands: [DetectedObjects], mirrored: Bool) -> some View {
        modifier(HandDetected(hands: hands, mirrored: mirrored))
    }
}
