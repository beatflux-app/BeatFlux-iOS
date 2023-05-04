//
//  InitializationPage.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/29/23.
//

import SwiftUI

struct InitializationPage: View {
    @StateObject var authHandler = AuthHandler()
    @StateObject var spotifyAuthHandler = SpotifyAuth.shared

    var body: some View {
        if authHandler.isUserLoggedIn {
            HomeView(authHandler: authHandler)
        }
        else {
            WebUIView(url: spotifyAuthHandler.signInURL!)
            //WelcomePageView(authHandler: authHandler)
        }
    }
}

struct InitializationPage_Previews: PreviewProvider {
    static var previews: some View {
        InitializationPage()
    }
}
