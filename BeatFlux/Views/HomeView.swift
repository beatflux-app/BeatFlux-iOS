//
//  HomeView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/23/23.
//

import SwiftUI
import Shimmer


struct HomeView: View {
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @EnvironmentObject var spotify: Spotify
    
    @State var showSpotifyLinkPrompt = false
    
    @State var isLoading = false
    @State var showSettings = false
    
    var size: CGFloat = 170
    
    var body: some View {
        VStack {
            TopBarView(showSettings: $showSettings)
                .environmentObject(beatFluxViewModel)

            ScrollView {
                
                HStack {
                    Text("Playlists")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.leading)
                
                Grid(alignment: .center) {
                    ForEach(0..<10) { index in
                        GridRow {
                            
                            PlaylistGridSquare(size: size)
                            
                            PlaylistGridSquare(size: size)

                            
                        }
                        .shimmering()
                        .padding(.horizontal)
                        .padding(.bottom)
                        
                        
                    }
                    
                    
                    
                }

                
            }
            .refreshable {
                await beatFluxViewModel.retrieveUserData()
                
                
            }
        }
        .sheet(isPresented: $showSpotifyLinkPrompt, onDismiss: {
            beatFluxViewModel.userData?.account_link_shown = true
        }) {
            SpotifyPopup(showSpotifyLinkPrompt: $showSpotifyLinkPrompt)
                .environmentObject(spotify)
                .environmentObject(beatFluxViewModel)
        }
        .onChange(of: beatFluxViewModel.isViewModelFullyLoaded, perform: { newValue in
            if beatFluxViewModel.isViewModelFullyLoaded == true {
                
                if let userData = beatFluxViewModel.userData {
                    if !userData.account_link_shown && userData.spotify_data?.authorization_manager == nil {
                        showSpotifyLinkPrompt = true
                    }
                }
            }
        })
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(showSettings: $showSettings)
        }

        
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(BeatFluxViewModel())
            .environmentObject(Spotify())
    }
}

private struct PlaylistGridSquare: View {
    var size: CGFloat
    var body: some View {
        VStack(alignment: .leading) {
            Rectangle()
                .frame(width: size, height: size, alignment: .center)
                .foregroundColor(Color(UIColor.systemGray5))
                .cornerRadius(16)
            VStack(alignment: .leading) {
                Text("Playlist")
                Text("Playist Author")
                
            }
            .redacted(reason: .placeholder)
            .padding(.leading)
            
            
        }
    }
}

private struct TopBarView: View {
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @Binding var showSettings: Bool
    
    var body: some View {
        HStack {
            Image("BeatFluxLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40)
                .cornerRadius(16)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .leading) {
            Circle()
                .frame(width: 35)
                .padding(.leading)
                .foregroundColor(Color(UIColor.systemGray5))
        }
        
        .overlay(alignment: .trailing) {
            Button {
                showSettings.toggle()
//                AuthHandler.shared.signOut()
            } label: {
                Circle()
                    .frame(width: 35)
                    .padding(.trailing)
                    .foregroundColor(Color(UIColor.systemGray5))
            }
            .disabled(!beatFluxViewModel.isViewModelFullyLoaded)

            
        }
    }
}
