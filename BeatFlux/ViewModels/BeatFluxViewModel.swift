//
//  BeatFluxViewModel.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/3/23.
//

import Foundation

class BeatFluxViewModel: ObservableObject {
    private let spotifyAPI = SpotifyAPI()
    
    @Published var isSpotifyAuthenticated = false
    
    func authenticateSpotify() {
        spotifyAPI.authenticate { success in
            DispatchQueue.main.async {
                self.isSpotifyAuthenticated = success
            }
        }
    }
}
