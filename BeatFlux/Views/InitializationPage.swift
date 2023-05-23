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
    @EnvironmentObject var authHandler: AuthHandler
    @EnvironmentObject var databaseHandler: DatabaseHandler
    @EnvironmentObject var spotify: Spotify
    @State private var cancellables: Set<AnyCancellable> = []


    
    var body: some View {
        if authHandler.isUserLoggedIn {
            HomeView(authHandler: authHandler)
        }
        else {
            WelcomePageView()
                .environmentObject(authHandler)
        }
    }
    
    
}

struct InitializationPage_Previews: PreviewProvider {
    
    static var previews: some View {
        InitializationPage()
            .environmentObject(AuthHandler())
            .environmentObject(Spotify())
            .environmentObject(DatabaseHandler())
    }
}
