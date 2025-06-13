//
//  MainContent.swift
//  AIApp
//
//  Created by Carlos Xavier Carvajal Villegas on 13/6/25.
//

import SwiftUI

struct MainContent: View {
    var body: some View {
        TabView {
            Tab("Intelligence", systemImage: "apple.intelligence") {
                AppleIntelligenceView()
            }
            Tab("Vision", systemImage: "eye") {
                VisionLibraryView()
            }
        }
    }
}

#Preview {
    MainContent()
}
