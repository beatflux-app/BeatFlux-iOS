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
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hey there!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("To use BeatFlux, link your preferred music service. To explore, swipe down the pop-up.")
                        .foregroundColor(.secondary)
                }
                .padding([.horizontal])
                
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
                    Button(action: { showSpotifyLinkPrompt.toggle() }) {
                        Text("")
                    }.buttonStyle(ExitButtonStyle(buttonSize: 30, symbolScale: 0.4))
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
        
        print("HANDLE URL: received redirect from Spotify: '\(url)'")        
        
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
            }
        }
        
        DispatchQueue.main.async {
            self.spotify.authorizationState = String.randomURLSafe(length: 128)
        }
        
    }
    
    func getPlaylists(priority: DatabaseHandler.Priorities) async {
        let playlists = try? await spotify.getUserPlaylists(priority: priority)
        guard let playlists = playlists else {
            return
        }
        
        for playlist in playlists.items {
            let details = await spotify.convertSpotifyPlaylistToCustom(playlist: playlist)
            guard let details = details else { return }
            if let index = spotify.spotifyData.playlists.firstIndex(where: { $0.playlist.id == details.playlist.id }) { //check if the playlist already exists; if it does overwrite it
                DispatchQueue.main.async {
                    spotify.spotifyData.playlists[index] = details
                }
                await spotify.uploadSpecificFieldFromPlaylistCollection(playlist: details, delete: false)
            }
            else {
                DispatchQueue.main.async {
                    spotify.spotifyData.playlists.append(details)
                }
                await spotify.uploadSpecificFieldFromPlaylistCollection(playlist: details, delete: false)
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
