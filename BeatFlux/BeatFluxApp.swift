//
//  BeatFluxApp.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/23/23.
//

import SwiftUI
import FirebaseCore

@main
struct BeatFluxApp: App {
    
    @State var beatFluxViewModel = BeatFluxViewModel()
    
    init() {
        FirebaseApp.configure()
        beatFluxViewModel.authenticateSpotify()
    }
    
    var body: some Scene {
        
        WindowGroup {
            InitializationPage()
                .environmentObject(beatFluxViewModel)
        }
    }
}
