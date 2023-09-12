//
//  ExportPlaylistView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 7/4/23.
//

import SwiftUI
import SpotifyWebAPI

struct ExportPlaylistView: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @EnvironmentObject var spotify: Spotify
    
    @Binding var showExportView: Bool
    
    var playlistToExport: PlaylistInfo
    
    var body: some View {
        NavigationView {
            Form {
                NavigationLink(destination: CreateNewPlaylistView(playlistToExport: playlistToExport, showExportView: $showExportView)) {
                    HStack(spacing: 13) {
                        Image(systemName: "plus.square.fill")
                            .font(.largeTitle)
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Create as a new playlist")
                                .foregroundColor(.primary)
                                .fontWeight(.semibold)
                                .font(.headline)
                            Text("Creates a new playlist in your library")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }
                }
                
                if spotify.userPlaylists.first(where: { $0.playlist.id == playlistToExport.playlist.id }) != nil {
                    
                    if let currentUserId = spotify.currentUser?.id,
                       let playlistOwnerId = playlistToExport.playlist.owner?.id,
                       currentUserId == playlistOwnerId {
                        
                        Button {
                            let uris = spotify.retrieveTrackURIFromPlaylist(playlist: playlistToExport)

                            spotify.replaceAllSongsInPlaylist(playlistToExport.playlist.uri, with: uris)
                            
                            showExportView = false
                        } label: {
                            HStack(spacing: 13) {
                                Image(systemName: "arrow.left.arrow.right.square.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.accentColor)
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Overwrite your old playlist")
                                        .foregroundColor(.primary)
                                        .fontWeight(.semibold)
                                        .font(.headline)
                                    Text("Soon to be removed")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .disabled(true)
                    }
                }
            }
            .navigationTitle("Export Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}
