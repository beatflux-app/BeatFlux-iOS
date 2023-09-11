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

    @State private var selectedTab = 0
    
    init() {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(named: "AccentColor")
    }
    
    var body: some View {
        if beatFluxViewModel.isUserLoggedIn {
            TabView(selection: $selectedTab) {
                HomeView()
                    .onAppear {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                    .environmentObject(beatFluxViewModel)
                    .environmentObject(spotify)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                SettingsView()
                    .onAppear {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(1)
                    
            }
            
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
