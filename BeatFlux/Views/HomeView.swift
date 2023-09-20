//
//  HomeView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/23/23.
//

import SwiftUI
import SpotifyWebAPI
import Combine
import Shimmer

struct HomeView: View {
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @EnvironmentObject var spotify: Spotify

    @State var showSpotifyLinkPrompt = false
    @State var isLoading = false
    @State var showSpotifyPlaylistListView: Bool = false
    
    
    init() {

//         //UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
//         //UINavigationBar.appearance().shadowImage = UIImage()
//         UINavigationBar.appearance().isTranslucent = false
//         UINavigationBar.appearance().tintColor = .clear
//         UINavigationBar.appearance().backgroundColor = .systemBackground
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    
                        if beatFluxViewModel.isViewModelFullyLoaded && spotify.isBackupsLoaded {
                            if beatFluxViewModel.userData != nil {
                                if !spotify.spotifyData.playlists.isEmpty {
                                    let playlists = spotify.spotifyData.playlists
                                    let chunks = playlists.chunked(size: 2)
                                    
                                    
                                    Grid {
                                        ForEach(0..<chunks.count, id: \.self) { index in
                                                GridRow(alignment: .top) {
                                                    ForEach(chunks[index], id: \.self) { playlist in
                                                        PlaylistGridSquare(playlistInfo: playlist)
                                                            .frame(maxWidth: .infinity, alignment: .leading) // Align to leading
                                                    }
                                                }
                                            }
                                    }
                                    .padding(.horizontal)
                                }
                                else {
                                    NoPlaylistsFoundView()
                                }
                            }
                        }
                    
                }
                .navigationTitle("Backups")
                .refreshable {
                    Task {
                        await spotify.refreshUsersPlaylists(options: .all, priority: .low, source: .default)
                    }
                }
                .scrollIndicators(.hidden)
                .toolbarBackground(Color(UIColor.systemBackground), for: .navigationBar)
                
            }
            .overlay {
                VStack(spacing: 15) {
                    ProgressView()

                    Text("Loading...")
                        .foregroundStyle(.secondary)
                        

                }
                .opacity(beatFluxViewModel.isViewModelFullyLoaded && spotify.isBackupsLoaded ? 0 : 1)
            }
            
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        showSpotifyPlaylistListView.toggle()
                    } label: {
                        Circle()
                            .frame(width: 65)
                            .foregroundStyle(Color.accentColor)
                            .overlay {
                                Image(systemName: "plus")
                                    .foregroundStyle(.white)
                                    .fontWeight(.bold)
                                    .font(.title3)
                            }
                            .shadow(radius: 16)
                        
                        
                        
                    }
                    .buttonStyle(ShrinkOnHoverButtonStyle())
                    .disabled(!beatFluxViewModel.isViewModelFullyLoaded)
                }
                .padding([.trailing, .bottom])
                
                
                
                
            }
        }
        

        .sheet(isPresented: $showSpotifyPlaylistListView) {
            SpotifyPlaylistListView()
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
                    if !userData.account_link_shown && spotify.spotifyData.authorization_manager == nil {
                        showSpotifyLinkPrompt = true
                    }
                }
            }
        })
        
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(BeatFluxViewModel())
            .environmentObject(Spotify())
    }
}


struct ShrinkOnHoverButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .opacity(configuration.isPressed ? 1 : 1)  // Set opacity to 1 when pressed
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut, value: configuration.isPressed)
    }
}





private struct NoPlaylistsFoundView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "questionmark.app.dashed")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No Backups Found")
                .foregroundStyle(.secondary)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top, 5)
            
            
        }
    }
}

private struct PlaylistGridSquare: View {
    var playlistInfo: PlaylistInfo
    @EnvironmentObject var spotify: Spotify
    @State var showExportView: Bool = false
    @State var showPlaylistVersionHistory = false
    @State var showSnapshotAlert = false
    
    var body: some View {
        
        
        
        VStack(alignment: .leading) {
            
            if !playlistInfo.playlist.images.isEmpty {
                
                AsyncImage(urlString: playlistInfo.playlist.images[0].url.absoluteString) {
                    Rectangle()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: (UIScreen.main.bounds.width / 2) - 25, height: (UIScreen.main.bounds.width / 2) - 25)
                        .foregroundColor(.secondary)
                        .shimmering()
                } content: {
                    Image(uiImage: $0)
                        .resizable()
                        .scaledToFill()
                        .frame(width: (UIScreen.main.bounds.width / 2) - 25, height: (UIScreen.main.bounds.width / 2) - 25)
                        .clipped()
                        
                }
                .clipped()
                .cornerRadius(12)
            }
            else {
                Rectangle()
                    .foregroundStyle(Color(UIColor.tertiarySystemBackground))
                    .aspectRatio(contentMode: .fill)
                    .frame(width: (UIScreen.main.bounds.width / 2) - 25, height: (UIScreen.main.bounds.width / 2) - 25)
                    .redacted(reason: .placeholder)
                    .clipped()
                    .cornerRadius(12)
                    .overlay {
                        Text("?")
                            .font(.largeTitle)
                    }
            }
            

            VStack(alignment: .leading, spacing: 0) {
                Text(playlistInfo.playlist.name)
                    .fontWeight(.semibold)
                
                Text(playlistInfo.playlist.owner?.displayName ?? "Unknown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 5)
            

            
            
                
            
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 5)
        
        .background(ContainerRelativeShape().fill(Color(uiColor: .systemBackground)))
        .contextMenu(ContextMenu(menuItems: {
            Button {
                showExportView = true
            } label: {
                HStack {
                    Text("Export")
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                    
                }
            }
            
            Section("Snapshots") {
                Button {
                    Task {
                        let snapshots = await self.spotify.getPlaylistSnapshots(playlist: playlistInfo)
                        
                        if snapshots.count < 2 {
                            self.spotify.uploadPlaylistSnapshot(snapshot: PlaylistSnapshot(playlist: playlistInfo, versionDate: Date()))
                        }
                        else {
                            showSnapshotAlert = true
                        }
                    }

                        
                    
                    
                } label: {
                    HStack {
                        Text("Create Snapshot")
                        Spacer()
                        Image(systemName: "plus")
                    }
                }

                Button {
                    showPlaylistVersionHistory = true
                } label: {
                    HStack {
                        Text("Snapshots")
                        Spacer()
                        Image(systemName: "camera.aperture")
                    }
                }
            }
            
            

        }))
        .alert(isPresented: $showSnapshotAlert) {
            Alert(title: Text("Snapshot Error"), message: Text("You can only save two snapshots at a time!"), dismissButton: .default(Text("Ok")))
        }
        .sheet(isPresented: $showExportView) {
            NavigationView {
                ExportPlaylistView(showExportView: $showExportView, playlistToExport: playlistInfo)
            }
            
        }
        .sheet(isPresented: $showPlaylistVersionHistory) {
            
            PlaylistSnapshotView(showPlaylistVersionHistory: $showPlaylistVersionHistory, playlistInfo: playlistInfo)

        }
    }
}

