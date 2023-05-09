//
//  InitializationPage.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/29/23.
//

import SwiftUI
import Combine
import SpotifyWebAPI

struct InitializationPage: View {
    @StateObject var authHandler = AuthHandler()
    @EnvironmentObject var spotify: Spotify
    @State private var cancellables: Set<AnyCancellable> = []

    var body: some View {
        if authHandler.isUserLoggedIn {
            HomeView(authHandler: authHandler)
        }
        else {
            let url = spotify.authorize()
            WebUIView(url: url)

//            WelcomePageView(authHandler: authHandler)
        }
    }
    
    
}

struct InitializationPage_Previews: PreviewProvider {
    static let spotify: Spotify = {
        let spotify = Spotify()
        spotify.isAuthorized = true
        return spotify
    }()
    
    static var previews: some View {
        InitializationPage()
            .environmentObject(spotify)
    }
}
