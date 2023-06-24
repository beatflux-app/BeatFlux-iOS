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
                    NavigationLink(destination: SpotifyAuthenticationView(alertTitle: $alertTitle, alertMessage: $alertMessage, showAlert: $showAlert, showSpotifyLinkPrompt: $showSpotifyLinkPrompt, url: spotify.authorize()).environmentObject(beatFluxViewModel).environmentObject(spotify)) {
                        
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
        
        DispatchQueue.main.async {
            spotify.isRetrievingTokens = true
        }
        

        spotify.requestAccessAndRefreshTokens(url: url) { result, error in
            if let error = error {
                alertTitle =
                    "Couldn't Authorization With Your Account"
                alertMessage = error.localizedDescription
    
                showAlert = true
                
            }
            else {
                showSpotifyLinkPrompt = false

                getPlaylists()
            }
        }
        
        DispatchQueue.main.async {
            self.spotify.authorizationState = String.randomURLSafe(length: 128)
        }
        
    }
    
    func getPlaylists() {
        spotify.getUserPlaylists { playlists in
            guard let playlists = playlists else {
                print("No playlists")
                return
            }
            
            for playlist in playlists.items {
                spotify.retrievePlaylistItem(fetchedPlaylist: playlist) { playlistDetails in
                    let playlistDetails = PlaylistDetails(playlist: playlistDetails.playlist, tracks: playlistDetails.tracks, lastFetched: Date())
                    
                    if let index = beatFluxViewModel.userData?.spotify_data.playlists.firstIndex(where: { $0.playlist.id == playlistDetails.playlist.id }) { //check if the playlist already exists; if it does overwrite it
                        DispatchQueue.main.async {
                            beatFluxViewModel.userData?.spotify_data.playlists[index] = playlistDetails
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            beatFluxViewModel.userData?.spotify_data.playlists.append(playlistDetails)
                        }
                    }
                    


                }
            }

        }
    }
}

struct SpotifyPopup_Previews: PreviewProvider {
    static var previews: some View {
        SpotifyPopup(showSpotifyLinkPrompt: .constant(true))
            .environmentObject(BeatFluxViewModel())
            .environmentObject(Spotify())
    }
}
