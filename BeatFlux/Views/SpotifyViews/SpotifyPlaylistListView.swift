//
//  PlaylistListView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 6/21/23.
//

import SwiftUI

struct SpotifyPlaylistListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var spotify: Spotify
    @State var loadingPlaylistID: String?
    
    var body: some View {
        NavigationView {
            Group {
                    Form {
                        Section("Your Spotify Library") {
                            if spotify.userPlaylists.isEmpty {
                                Text("None")
                                    .foregroundStyle(.secondary)
                            }
                            else {
                                ForEach(spotify.userPlaylists, id: \.self) { playlist in
                                    PlaylistRow(loadingPlaylistID: $loadingPlaylistID, playlist: playlist)
                                        .environmentObject(spotify)
                                    
                                }
                            }

                        }
                        
                        Section("Playlists From Other Accounts") {
                            if spotify.spotifyData.playlists.isEmpty {
                                Text("None")
                                    .foregroundStyle(.secondary)
                            }
                            else {
                                ForEach(spotify.spotifyData.playlists, id: \.self) { playlist in
                                    if (spotify.userPlaylists.first(where:  { $0.playlist.id == playlist.playlist.id }) == nil) {
                                        
                                        PlaylistRow(loadingPlaylistID: $loadingPlaylistID, playlist: playlist)
                                            .environmentObject(spotify)

                                    }
                                }
                            }
                            
                        }
                        
                    }
            }
            .navigationTitle("Add Playlists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button(action: { dismiss() }) {
                        Text("")
                    }.buttonStyle(ExitButtonStyle(buttonSize: 30, symbolScale: 0.4))

                }
                
                
            }
        }
    }
}




private struct PlaylistImage: View {
    
    var playlist: PlaylistInfo

    
    var body: some View {
        
        HStack(spacing: 15) {
            if !playlist.playlist.images.isEmpty {
                AsyncImage(urlString: playlist.playlist.images[0].url.absoluteString) {
                    Rectangle()
                        .foregroundStyle(Color(UIColor.secondarySystemGroupedBackground))
                        .aspectRatio(contentMode: .fill)
                        .redacted(reason: .placeholder)
                } content: {
                    Image(uiImage: $0)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipped()
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
    
    var body: some View {
        HStack {
            PlaylistImage(playlist: playlist)
            
            VStack(alignment: .leading) {
                Text(playlist.playlist.name)
                    .fontWeight(.semibold)
                Text(playlist.playlist.owner?.displayName ?? "Unknown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()

            Button {
                if spotify.spotifyData.playlists.firstIndex(where: { $0.playlist.id == playlist.playlist.id }) != nil {
                    //playlist is already saved
                    isPresentingConfirm = true
                }
                else {
                    loadingPlaylistID = playlist.playlist.id
                    spotify.backupPlaylist(playlist: playlist) {
                        loadingPlaylistID = nil
                    }
                    
                    
                }
            } label: {
                if loadingPlaylistID == playlist.playlist.id {
                    LoadingIndicator(color: .accentColor, lineWidth: 3.0)
                            .frame(width: 15, height: 15)
                }
                else {
                    Image(systemName: (spotify.spotifyData.playlists.first(where: { $0.playlist.id == playlist.playlist.id }) != nil) ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                }
                
            }
        }
        .confirmationDialog("Are you sure?",
          isPresented: $isPresentingConfirm) {
          Button("Delete Backup", role: .destructive) {
              if let savedPlaylistIndex = spotify.spotifyData.playlists.firstIndex(where: { $0.playlist.id == playlist.playlist.id }) {
                  //playlist is already saved
                  spotify.spotifyData.playlists.remove(at: savedPlaylistIndex)
                  Task {
                      await self.spotify.uploadSpotifyData()
                  }
              }
           }
         } message: {
             Text("You cannot undo this action")
           }

    }

}

struct PlaylistListView_Previews: PreviewProvider {
    static var previews: some View {
        SpotifyPlaylistListView()
            .environmentObject(Spotify())
    }
}
