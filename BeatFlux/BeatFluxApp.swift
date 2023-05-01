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
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            InitializationPage()
        }
    }
}
