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
import Refresher

struct HomeView: View {
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @EnvironmentObject var spotify: Spotify

    @State var showSpotifyLinkPrompt = false
    @State var isLoading = false
    @State var showSpotifyPlaylistListView: Bool = false
    @State var showBanner: Bool = false
    @State var bannerData: BannerModifier.BannerData = BannerModifier.BannerData(imageIcon: Image(systemName: "camera.aperture"),title: "Added Snapshot")
    @State var searchQuery = ""
    
    init() {

//         //UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
//         //UINavigationBar.appearance().shadowImage = UIImage()
//         UINavigationBar.appearance().isTranslucent = false
//         UINavigationBar.appearance().tintColor = .clear
//         UINavigationBar.appearance().backgroundColor = .systemBackground
    }
    
    var body: some View {
        
        NavigationView {
            ZStack {
                ScrollView {
                        if beatFluxViewModel.isViewModelFullyLoaded && spotify.isBackupsLoaded {
                            if beatFluxViewModel.userData != nil {
                                if !spotify.spotifyData.playlists.isEmpty {
                                    var filteredChunkedPlaylists: [[PlaylistInfo]] {
                                        let playlists = spotify.spotifyData.playlists
                                        let flatChunks = playlists.chunked(size: 2).flatMap { $0 }
                                        let filteredChunks = flatChunks.filter {
                                            searchQuery.isEmpty ? true : $0.playlist.name.contains(searchQuery)
                                        }
                                        return stride(from: 0, to: filteredChunks.count, by: 2).map {
                                            Array(filteredChunks[$0..<min($0+2, filteredChunks.count)])
                                        }
                                    }
                                    
                                    Grid {
                                        ForEach(0..<filteredChunkedPlaylists.count, id: \.self) { index in
                                                GridRow(alignment: .top) {
                                                    ForEach(filteredChunkedPlaylists[index], id: \.self) { playlist in
                                                        PlaylistGridSquare(playlistInfo: playlist, showBanner: $showBanner)
                                                            .frame(maxWidth: .infinity, alignment: .leading) // Align to leading
                                                    }
                                                }
                                            }
                                    }
                                    .padding(.horizontal)
                                    .animation(.default, value: filteredChunkedPlaylists)
                                    .searchable(text: $searchQuery)
                                }
                                else {
                                    NoPlaylistsFoundView()
                                }
                            }
                        }
                        
                    
                }
                .refresher(style: .default) {
                    await spotify.refreshUsersPlaylists(options: .all, priority: .low, source: .default)
                }
                .navigationTitle("Backups")  
                .scrollIndicators(.hidden)
                .toolbarBackground(Color(UIColor.systemBackground), for: .navigationBar)
                
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
            .overlay {
                VStack(spacing: 15) {
                    ProgressView()

                    Text("Loading...")
                        .foregroundStyle(.secondary)
                        

                }
                .opacity(beatFluxViewModel.isViewModelFullyLoaded && spotify.isBackupsLoaded ? 0 : 1)
            }
            
            
            
        }
        
        
        .banner(data: $bannerData, show: $showBanner)

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
    @Binding var showBanner: Bool
    
    var body: some View {
        
        
        NavigationLink(destination: PlaylistInfoView(playlistInfo: playlistInfo)) {
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
                        .foregroundColor(.primary)
                    
                    Text(playlistInfo.playlist.owner?.displayName ?? "Unknown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 5)
                

                
                
                    
                
            }
            
            .padding(.horizontal, 5)
            .padding(.vertical, 5)
            
            .background(ContainerRelativeShape().fill(Color(uiColor: .systemBackground)))
            
            
            .alert(isPresented: $showSnapshotAlert) {
                Alert(title: Text("Snapshot Limit Reached"), message: Text("You can only save two snapshots at a time!"), dismissButton: .default(Text("Ok")))
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
        .buttonStyle(PlainButtonStyle())
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
                            await self.spotify.uploadPlaylistSnapshot(snapshot: PlaylistSnapshot(id: UUID().uuidString, playlist: playlistInfo, versionDate: Date()))
                            withAnimation {
                                showBanner = true
                            }
                            
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
    }
}

