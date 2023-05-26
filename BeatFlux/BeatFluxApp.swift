//
//  BeatFluxApp.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/23/23.
//

import SwiftUI
import FirebaseCore
import SpotifyWebAPI

@main
struct BeatFluxApp: App {
    @StateObject var authHandler = AuthHandler()
    @StateObject var spotify = Spotify()
    
    init() {
        FirebaseApp.configure()
        
        SpotifyAPILogHandler.bootstrap()
        
        DatabaseHandler.shared.intializeSettings()
        
    }
    
    var body: some Scene {
        
        WindowGroup {
            InitializationPage()
                .environmentObject(spotify)
                .environmentObject(authHandler)
        }
    }
}

