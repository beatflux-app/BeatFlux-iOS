//
//  BeatFluxViewModel.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/3/23.
//

import Foundation

class BeatFluxViewModel: ObservableObject {
    
    @Published var isSpotifyAuthenticated = false
    @Published var spotifyAuth: SpotifyAuth = SpotifyAuth.shared
    
    
    func checkAndRefreshTokens() {
        spotifyAuth.checkAndRefreshTokens()
    }
    
    func authenticateSpotify() {
        
    }
}
