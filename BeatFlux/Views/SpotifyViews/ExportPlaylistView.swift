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
        
            Form {
                Section {
                    NavigationLink(destination: PlaylistInfoView(playlistInfo: playlistToExport, showMoreOptionsButton: false)) {
                        HStack(spacing: 13) {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.title)
                                .foregroundColor(.accentColor)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("View Playlist")
                                    .foregroundColor(.primary)
                                    .fontWeight(.semibold)
                                    .font(.headline)
                                Text("See the songs inside this playlist")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
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
