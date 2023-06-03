//
//  SpotifySettingsView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/31/23.
//

import SwiftUI
import Shimmer

struct SpotifySettingsView: View {
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @EnvironmentObject var spotify: Spotify
    @State var isPresentingConfirm = false
    @State var showSpotifyPopup = false
    
    var body: some View {
        Form {
            HStack(spacing: 15) {
                Image("SpotifyLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45)
                
                VStack(alignment: .leading) {
                    RedactedView(isRedacted: !beatFluxViewModel.isConnected, text: Text(spotify.currentUser?.displayName ?? "Account Not Linked").fontWeight(.semibold))
                        
                    Text("Spotify")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                Spacer()
                
                
                if spotify.currentUser != nil {
                    Button {
                        isPresentingConfirm = true
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .fontWeight(.semibold)
                    }
                    .confirmationDialog("Are you sure?",
                      isPresented: $isPresentingConfirm) {
                      Button("Deauthorize Account", role: .destructive) {
                          spotify.api.authorizationManager.deauthorize()
                       }
                     }
                }


            }
            
            
            
            Section {
                Button {
                    showSpotifyPopup.toggle()
                } label: {
                    HStack {
                        Spacer()
                        Text("Connect with")
                            .foregroundColor(.spotifyGreen)
                            .fontWeight(.medium)
                        Image("SpotifyLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20)
                        Spacer()
                    }
                    
                    
                    
                    
                    
                    
                }
                
            }
            
            


        }
        .navigationTitle("Spotify")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSpotifyPopup) {
            SpotifyPopup(showSpotifyLinkPrompt: $showSpotifyPopup)
                .environmentObject(spotify)
                .environmentObject(beatFluxViewModel)
        }
    }
}

struct SpotifySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SpotifySettingsView()
                .environmentObject(BeatFluxViewModel())
            .environmentObject(Spotify())
        }
    }
}
