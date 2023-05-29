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
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @EnvironmentObject var spotify: Spotify
    @State private var cancellables: Set<AnyCancellable> = []


    
    var body: some View {
        if beatFluxViewModel.isUserLoggedIn {
            HomeView()
                .environmentObject(beatFluxViewModel)
        }
        else {
            WelcomePageView()
                .environmentObject(beatFluxViewModel)
        }
    }
    
    
}

struct InitializationPage_Previews: PreviewProvider {
    
    static var previews: some View {
        InitializationPage()
            .environmentObject(BeatFluxViewModel())
            .environmentObject(Spotify())
    }
}
