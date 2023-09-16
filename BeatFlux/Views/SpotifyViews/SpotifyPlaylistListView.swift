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
    @State var isRefreshing: Bool = false
    
    
    var body: some View {
        NavigationView {
            Group {
                if spotify.isSpotifyInitializationLoaded {
                Form {
                    
                        Section("Your Spotify Library") {
                            
                            if spotify.userPlaylists.isEmpty {
                                Text("None")
                                    .foregroundStyle(.secondary)
                            }
                            else {
                                
                                    ForEach(spotify.userPlaylists.sorted(by: { $0.playlist.name < $1.playlist.name }), id: \.self) { playlist in
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
                else {
                    VStack(spacing: 15) {
                        Spacer()
                        ProgressView()
                        Text("LOADING...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
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
                        .foregroundStyle(Color.secondary)
                        .aspectRatio(contentMode: .fill)
                        .redacted(reason: .placeholder)
                        .frame(width: 50, height: 50)
                        .overlay {
                            ProgressView()
                        }
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
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if spotify.spotifyData.playlists.firstIndex(where: { $0.playlist.id == playlist.playlist.id }) != nil {
                //playlist is already saved
                isPresentingConfirm = true
            }
            else {
                
                Task {
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            loadingPlaylistID = playlist.playlist.id
                        }
                        
                    }
                    
                    await spotify.backupPlaylist(playlist: playlist)

                    
                    DispatchQueue.main.async {
                        withAnimation {
                            loadingPlaylistID = nil
                        }
                        
                    }
                    
                    
                }
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
                }
                else {
                    Image(systemName: (spotify.spotifyData.playlists.first(where: { $0.playlist.id == playlist.playlist.id }) != nil) ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                }
                    
                
            }
        }
        .disabled(loadingPlaylistID != nil)

        .confirmationDialog("Are you sure?",
          isPresented: $isPresentingConfirm) {
          Button("Delete Backup", role: .destructive) {
              if let savedPlaylistIndex = spotify.spotifyData.playlists.firstIndex(where: { $0.playlist.id == playlist.playlist.id }) {
                      // Make a copy of the playlist to delete
                      let playlistToDelete = spotify.spotifyData.playlists[savedPlaylistIndex]
                      
                      // Perform the deletion operation
                      Task {
                          withAnimation {
                              DispatchQueue.main.async {
                                  spotify.spotifyData.playlists.remove(at: savedPlaylistIndex)
                                  
                              }
                              
                          }
                          
                          await spotify.uploadSpecificFieldFromPlaylistCollection(playlist: playlistToDelete, delete: true)
                          
                          // If successful, update the array
                         
                          //await spotify.refreshUsersPlaylists(options: .backupPlaylists)
                          

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

