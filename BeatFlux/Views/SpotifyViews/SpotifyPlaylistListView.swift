//
//  PlaylistListView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 6/21/23.
//

import SwiftUI
import NukeUI
import Nuke

struct SpotifyPlaylistListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var spotify: Spotify
    @State var loadingPlaylistID: String?
    @State var isRefreshing: Bool = false
    
    var body: some View {
        NavigationView {
            Group {
                if spotify.isSpotifyInitializationLoaded {
                    Form {
                        
                            playlistSection(title: "Your Spotify Library", playlists: spotify.userPlaylists)
                            playlistSection(title: "Playlists From Other Accounts", playlists: spotify.spotifyData.playlists.filter { playlist in
                                spotify.userPlaylists.first(where: { $0.playlist.id == playlist.playlist.id }) == nil
                            })
                        
                        
                    }
                }
                else {
                    loadingView
                }
            }
            .navigationTitle("Add Playlists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(UIColor.systemBackground), for: .navigationBar)
            .toolbar {
                ToolbarItem {
                    dismissButton
                }
            }
        }
    }
    
    private func playlistSection(title: String, playlists: [PlaylistInfo]) -> some View {
        Section(title) {
            if playlists.isEmpty {
                Text("None").foregroundStyle(.secondary)
            } else {
                ForEach(playlists, id: \.self.playlist.id) { playlist in
                    PlaylistRow(loadingPlaylistID: $loadingPlaylistID, playlist: playlist)
                        .environmentObject(spotify)
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 15) {
            Spacer()
            ProgressView()
            Text("LOADING...")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
    
    private var dismissButton: some View {
        Button(action: { dismiss() }) {
            Text("")
        }
        .buttonStyle(ExitButtonStyle(buttonSize: 30, symbolScale: 0.4))
    }
}


private struct PlaylistImage: View {
    
    var playlist: PlaylistInfo

    
    var body: some View {
        
        HStack(spacing: 15) {
            if !playlist.playlist.images.isEmpty {
                LazyImage(url: playlist.playlist.images[0].url) { imageState in
                    if let image = imageState.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipped()
                    }
                    else {
                        Rectangle()
                            .foregroundStyle(Color.secondary)
                            .aspectRatio(contentMode: .fill)
                            .redacted(reason: .placeholder)
                            .frame(width: 50, height: 50)
                            .overlay {
                                ProgressView()
                            }
                    }

                }

                .clipped()
                .cornerRadius(8)
            }
            else {
                Rectangle()
                    .foregroundStyle(Color(UIColor.secondarySystemGroupedBackground))
                    .aspectRatio(contentMode: .fill)
                    .redacted(reason: .placeholder)
                    .frame(width: 50, height: 50)
                    .clipped()
                    .overlay {
                        Text("?")
                    }
                
            }
            

        }
    }
}

private struct PlaylistRow: View {
    @EnvironmentObject var spotify: Spotify
    @Binding var loadingPlaylistID: String?
    
    var playlist: PlaylistInfo
    
    @State private var isPresentingConfirm = false

    // Calculating it once here
    private var isPlaylistSaved: Bool {
        spotify.spotifyData.playlists.first(where: { $0.playlist.id == playlist.playlist.id }) != nil
    }
    
    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if isPlaylistSaved {
                isPresentingConfirm = true
            } else {
                handleBackup()
            }
        } label: {
            HStack {
                PlaylistImage(playlist: playlist)
                
                VStack(alignment: .leading) {
                    Text(playlist.playlist.name)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(playlist.playlist.owner?.displayName ?? "Unknown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if loadingPlaylistID == playlist.playlist.id {
                    ProgressView()
                } else {
                    Image(systemName: isPlaylistSaved ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                }
            }
        }
        .disabled(loadingPlaylistID != nil)
        .confirmationDialog("Are you sure?", isPresented: $isPresentingConfirm) {
            Button("Delete Backup", role: .destructive) {
                deleteBackup()
            }
        } message: {
            Text("You cannot undo this action")
        }
    }
    
    private func handleBackup() {
        Task {
            withAnimation(.easeInOut(duration: 0.3)) {
                loadingPlaylistID = playlist.playlist.id
            }
            await spotify.backupPlaylist(playlist: playlist)
            withAnimation {
                loadingPlaylistID = nil
            }
        }
    }
    
    private func deleteBackup() {
        if let savedPlaylistIndex = spotify.spotifyData.playlists.firstIndex(where: { $0.playlist.id == playlist.playlist.id }) {
            let playlistToDelete = spotify.spotifyData.playlists[savedPlaylistIndex]
            Task {
                spotify.spotifyData.playlists.remove(at: savedPlaylistIndex)
                
                
                await spotify.uploadSpecificFieldFromPlaylistCollection(playlist: playlistToDelete, delete: true, source: .default)
            }
        }
    }
}


struct PlaylistListView_Previews: PreviewProvider {
    static var previews: some View {
        SpotifyPlaylistListView()
            .environmentObject(Spotify())
    }
}

