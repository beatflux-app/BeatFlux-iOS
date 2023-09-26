//
//  BeatFluxApp.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/23/23.
//

import SwiftUI
import FirebaseCore
import SpotifyWebAPI
import TipKit

@main
struct BeatFluxApp: App {
    @StateObject var beatFluxViewModel = BeatFluxViewModel()
    @StateObject var spotify = Spotify()
    
    init() {

        
        
        FirebaseApp.configure()
        
        SpotifyAPILogHandler.bootstrap()        
    }
    
    var body: some Scene {
        
        WindowGroup {
            InitializationPage()
                .environmentObject(beatFluxViewModel)
                .environmentObject(spotify)
                .task {
                    if #available(iOS 17.0, *) {
                        try? Tips.configure([
                            .displayFrequency(.immediate),
                            .datastoreLocation(.applicationDefault)
                        ])
                    }
                }
        }
        
    }
}

