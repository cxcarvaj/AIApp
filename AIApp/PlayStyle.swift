//
//  PlayStyle.swift
//  AIApp
//
//  Created by Carlos Xavier Carvajal Villegas on 11/6/25.
//

import SwiftUI

struct PlayStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            if configuration.isOn {
                Image(systemName: "pause")
                    .contentTransition(.symbolEffect(.replace))
            } else {
                Image(systemName: "play")
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .symbolVariant(.fill)
        .font(.title)
    }
}
