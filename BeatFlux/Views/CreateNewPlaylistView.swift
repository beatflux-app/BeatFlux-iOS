//
//  CreateNewPlaylistView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 7/5/23.
//

import SwiftUI

struct CreateNewPlaylistView: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    
    
    @State var playlistName: String = ""
    @State var isPublic: Bool = false
    @State var isCollaborative: Bool = false
    @State var description: String = ""
    @State var isLoading: Bool = false
    
    var playlistToExport: PlaylistInfo
    @Binding var showExportView: Bool
    
    var body: some View {
        
        VStack {
            TextField("Playlist Name", text: $playlistName)
                .disabled(isLoading)
            
            Toggle(isOn: $isPublic) {
                Text("Is Public")
            }
            .disabled(isLoading)
            
            Toggle(isOn: $isCollaborative) {
                Text("Is Collaborative")
            }
            .disabled(isLoading)
            
            TextField("Description", text: $description)
                .disabled(isLoading)
            
            Button {
                isLoading = true
                spotify.uploadSpotifyPlaylistFromBackup(playlistInfo: playlistToExport, playlistName: playlistName, isPublic: isPublic, isCollaborative: isCollaborative, description: description) { playlistObject in
                    isLoading = false
                    showExportView = false
                }
                
                
            } label: {
                Text("Export backup")
            }
            .disabled(isLoading)
            
            
            
        }
        .navigationTitle("Playlist Details")
        
        
        //        PlaylistDetails(name: playlistInfo.playlist.name, isPublic: playlistInfo.playlist.isPublic, isCollaborative: playlistInfo.playlist.isCollaborative, description: playlistInfo.playlist.description))
    }
//
}
