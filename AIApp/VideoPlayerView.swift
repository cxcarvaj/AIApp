//
//  VideoPlayerView.swift
//  AIApp
//
//  Created by Carlos Xavier Carvajal Villegas on 11/6/25.
//


import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let player = AVPlayer(url: .bunny)
    
    @State private var play = false
    
    var body: some View {
        VideoPlayerView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                Button {
                    play.toggle()
                } label: {
                    Image(systemName: play ? "play" : "pause")
                        .symbolVariant(.fill)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .font(.title)
                .layoutPriority(1)
            }
    }
}

#Preview {
    VideoPlayerView()
}
