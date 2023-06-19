//
//  SpotifyPopup.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/28/23.
//

import SwiftUI
import Combine
import SpotifyWebAPI
import WebKit

struct SpotifyPopup: View {
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @EnvironmentObject var spotify: Spotify
    @Binding var showSpotifyLinkPrompt: Bool
    
    @State private var cancellables: Set<AnyCancellable> = []
    @State private var isWebViewShown = false
    
    @State var alertTitle = ""
    @State var alertMessage = ""
    @State var showAlert = false
    
    
    
    var body: some View {
        NavigationView {
            VStack {
                VStack(alignment: .leading) {
                    Text("Hey there!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    Text("To use BeatFlux, link your preferred music service. To explore, swipe down the pop-up.")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom)
                
                
                HStack {
                    Rectangle()
                        .frame(height: 1)
                    Image(systemName: "link")
                        .font(.caption)
                    Rectangle()
                        .frame(height: 1)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom)

                VStack {
                    NavigationLink(destination: SpotifyAuthenticationView(cancellables: $cancellables, alertTitle: $alertTitle, alertMessage: $alertMessage, showAlert: $showAlert, showSpotifyLinkPrompt: $showSpotifyLinkPrompt, url: spotify.authorize()).environmentObject(beatFluxViewModel).environmentObject(spotify)) {
                        
                        Rectangle()
                            .cornerRadius(30)
                            .frame(height: 50)
                            .foregroundColor(.accentColor)
                            .overlay {
                                Text("Sign In With Spotify")
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .overlay(alignment: .leading) {
                                        Image("SpotifyLogoWhite")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 25)
                                            .padding(.leading)
                                    }
                                
                            }
                            .padding(.horizontal)
                    }

                }
                
                Spacer()
                
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        showSpotifyLinkPrompt.toggle()
                    } label: {
                        Text("Not Now")
                            .fontWeight(.bold)
                    }

                }
            }
        }
        
        
    }
    
    
    
}

struct SpotifyAuthenticationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    
    @Binding var cancellables: Set<AnyCancellable>
    @Binding var alertTitle: String
    @Binding var alertMessage: String
    @Binding var showAlert: Bool
    @Binding var showSpotifyLinkPrompt: Bool
    
    let url: URL
    
    var body: some View {
        
        
        WebView(url: url) { url in
            handleURL(url)
        }
        .navigationBarTitle(Text("BeatFlux Authentication"), displayMode: .inline)
        
    }
    
    func handleURL(_ url: URL) {
            guard url.scheme == self.spotify.loginCallbackURL.scheme else {
                print("not handling URL: unexpected scheme: '\(url)'")
                print("Unexpected URL")
                return
            }
            
            print("received redirect from Spotify: '\(url)'")
            
            spotify.isRetrievingTokens = true

            spotify.api.authorizationManager.requestAccessAndRefreshTokens(
                redirectURIWithQuery: url,
                state: spotify.authorizationState
            )
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                self.spotify.isRetrievingTokens = false
                
                switch completion {
                case .finished:
                    spotify.getUserPlaylists { playlists in
                        guard let playlists = playlists else {
                            print("No playlists")
                            return
                            
                        }
                        
                        DispatchQueue.main.async {
                            var spotifyData = SpotifyDataModel(authorization_manager: spotify.api.authorizationManager)
                            
                            // Create a DispatchGroup
                            let group = DispatchGroup()

                            for playlist in playlists.items {
                                // Enter the group before each async operation
                                group.enter()

                                spotify.api.playlistItems(playlist.uri)
                                    .sink(receiveCompletion: { completion in
                                        switch completion {
                                        case .finished:
                                            print("Finished fetching playlist items")
                                        case .failure(let error):
                                            print("Failed to get playlist items: \(error)")
                                        }
                                        
                                        // Leave the group when each operation is complete
                                        group.leave()
                                    }, receiveValue: { pagingObject in
                                        let playlistDetails = PlaylistDetails(playlist: playlist, tracks: pagingObject.items)
                                        spotifyData.playlists.append(playlistDetails)
                                        print("appended")
                                    })
                                    .store(in: &cancellables)
                            }
                            
                            // Set up a notification for when all tasks are complete
                            group.notify(queue: .main) {
                                print(spotifyData)
                                beatFluxViewModel.userData?.spotify_data = spotifyData
                            }
                        }

                        
                    }
                    
                    showSpotifyLinkPrompt = false
                case .failure(let error):
                    print("couldn't retrieve access and refresh tokens:\n\(error)")
                    if let authError = error as? SpotifyAuthorizationError,
                       authError.accessWasDenied {
                        alertTitle = "You Denied The Authorization Request :("
                        alertMessage = ""
                        showAlert = true
                    }
                    else {
                        alertTitle =
                            "Couldn't Authorization With Your Account"
                        alertMessage = error.localizedDescription
                        showAlert = true
                    }
                }

            })
            .store(in: &cancellables)
            
            self.spotify.authorizationState = String.randomURLSafe(length: 128)
            
        }
}

struct SpotifyPopup_Previews: PreviewProvider {
    static var previews: some View {
        SpotifyPopup(showSpotifyLinkPrompt: .constant(true))
            .environmentObject(BeatFluxViewModel())
            .environmentObject(Spotify())
    }
}
