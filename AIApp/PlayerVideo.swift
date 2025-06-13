//
//  PlayerVideoView.swift
//  AIApp
//
//  Created by Carlos Xavier Carvajal Villegas on 11/6/25.
//

import SwiftUI
import AVKit

struct PlayerVideoView: UIViewControllerRepresentable {
    typealias UIViewControllerType = PlayerVideo
    
    func makeUIViewController(context: Context) -> PlayerVideo {
        PlayerVideo()
    }
    
    func updateUIViewController(_ uiViewController: PlayerVideo, context: Context) {
        
    }
}

final class PlayerVideo: UIViewController {
    var layer: AVPlayerLayer?
    var player: AVPlayer?
    
    override func viewDidLoad() {
        let asset = AVPlayerItem(url: .bunny)
        player = AVPlayer(playerItem: asset)
        layer = AVPlayerLayer(player: player)
        layer?.frame = view.bounds
        if let layer {
            view.layer.addSublayer(layer)
        }
        
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        player?.play()
    }
    
    override func viewDidLayoutSubviews() {
        view.layer.sublayers?.first?.frame = view.bounds
    }
}
