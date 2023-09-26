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
import TipKit

struct HomeView: View {
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @EnvironmentObject var spotify: Spotify

    @State var showSpotifyLinkPrompt = false
    @State var isLoading = false
    @State var showSpotifyPlaylistListView: Bool = false
    @State var showBanner: Bool = false
    @State var bannerData: BannerModifier.BannerData = BannerModifier.BannerData(imageIcon: Image(systemName: "camera.aperture"),title: "Added Snapshot")
    @State var searchQuery = ""
    @State var presentRefreshInfo = false
    
    
    var body: some View {
        
        NavigationView {
            ZStack {
                
                    if beatFluxViewModel.isViewModelFullyLoaded && spotify.isBackupsLoaded && beatFluxViewModel.isConnected {
                            if beatFluxViewModel.userData != nil {
                                VStack(alignment: .leading) {
                                    if #available(iOS 17, *) {
                                        TipView(RefreshTip()) { action in
                                            presentRefreshInfo.toggle()
                                        }
                                    }
                                    if !spotify.spotifyData.playlists.isEmpty {
                                        ScrollView {
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
                                            
                                            .animation(.default, value: filteredChunkedPlaylists)
                                            .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always))
                                            .padding(.horizontal)
                                    }
                                        .refresher(style: .default) {
                                            await spotify.refreshUsersPlaylists(options: .libraryPlaylists, priority: .low, source: .default)
                                        }
                                        .toolbarBackground(Color(UIColor.systemBackground), for: .navigationBar)
                                        .scrollIndicators(.hidden)

                                }
                                    
                                else {
                                    NoPlaylistsFoundView(showSpotifyLinkPrompt: $showSpotifyLinkPrompt)
                                }
                                
                            }
                        }
                        
                    
                }
                
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        Button {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            showSpotifyPlaylistListView.toggle()
                        } label: {
                            if #available(iOS 17.0, *) {
                                Circle()
                                    .popoverTip(AddBackUpTip(), arrowEdge: .bottom)
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
                            else {
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
                            
                            
                            
                            
                        }
                        .buttonStyle(ShrinkOnHoverButtonStyle())
                        .disabled(!beatFluxViewModel.isViewModelFullyLoaded)

                    }
                    .padding([.trailing, .bottom])
                }
            }
            .navigationTitle("Backups")
            .toolbar(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)

            .overlay {
                if beatFluxViewModel.isConnected {
                    VStack(spacing: 15) {
                        ProgressView()

                        Text("Loading...")
                            .foregroundStyle(.secondary)
                            

                    }
                    .opacity(beatFluxViewModel.isViewModelFullyLoaded && spotify.isBackupsLoaded ? 0 : 1)
                }
                else {
                    VStack(spacing: 15) {
                        Text("No Network Connection")
                            .foregroundStyle(.secondary)
                    }
                    .opacity(beatFluxViewModel.isConnected ? 0 : 1)
                }
                
            }
            
            
            
        }
        
        
        .banner(data: $bannerData, show: $showBanner)

        .sheet(isPresented: $showSpotifyPlaylistListView) {
            SpotifyPlaylistListView()
        }
        .sheet(isPresented: $presentRefreshInfo, content: {
            PlaylistRefreshInformation()
        })
        
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

@available(iOS 17, *)
struct RefreshTip: Tip {
    var title: Text {
        Text("Playlist Refresh")
    }


    var message: Text? {
        Text("Playlists refresh automatically every 10 minutes")
    }


    var image: Image? {
        Image(systemName: "timer")
    }
    
    var actions: [Action] {
        
        [Action(id: "learn-more", {
            Text("Learn more")
        })]

    }
}

@available(iOS 17, *)
struct AddBackUpTip: Tip {
    var title: Text {
        Text("Add Backups")
    }


    var message: Text? {
        Text("Press to backup your playlists")
    }


    var image: Image? {
        Image(systemName: "hand.point.up.left.fill")
    }
    
}

struct PlaylistRefreshInformation: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Text("Our BeatFlux servers automatically refresh your playlists every 10 minutes. This ensures that you're playlists are always up to data.")
            }
            .navigationTitle("Refresh Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    dismissButton
                }
            }
        }

    }
    
    private var dismissButton: some View {
        Button(action: { dismiss() }) {
            Text("")
        }
        .buttonStyle(ExitButtonStyle(buttonSize: 30, symbolScale: 0.4))
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
    @EnvironmentObject var spotify: Spotify
    @Binding var showSpotifyLinkPrompt: Bool
    
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
            
            
            if !spotify.isAuthorized {
                Button {
                    showSpotifyLinkPrompt = true
                } label: {
                    HStack(spacing: 15) {
                        Image("SpotifyLogoWhite")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 25)
                        
                        
                        Text("Connect To Spotify")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                            
                            
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .foregroundColor(.accentColor)
                    }
                    
                }
                .padding(.top)

            }
            
            Spacer()
            
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
            VStack(alignment: .center) {
                
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
                
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(playlistInfo.playlist.name)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(playlistInfo.playlist.owner?.displayName ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 5)
                    
                    Spacer()
                }

                

                
                
                    
                
            }
            
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
        .contextMenu(menuItems: {
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
                        let snapshots = await self.spotify.getPlaylistSnapshots(playlist: playlistInfo, location: .cloud)
                        
                        if snapshots.count < 2 {
                            withAnimation {
                                showBanner = true
                            }
                            await self.spotify.uploadPlaylistSnapshot(snapshot: PlaylistSnapshot(id: UUID().uuidString, playlist: playlistInfo, versionDate: Date()), playlistInfo: playlistInfo)
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
        }, preview: {
            VStack(alignment: .leading) {
                if !playlistInfo.playlist.images.isEmpty {
                    
                    AsyncImage(urlString: playlistInfo.playlist.images[0].url.absoluteString) {
                        Rectangle()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 300, height: 300)
                            .foregroundColor(.secondary)
                            .shimmering()
                    } content: {
                        Image(uiImage: $0)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 300, height: 300)
                            .clipped()
                            
                    }
                    .clipped()
                    .cornerRadius(12)
                }
                else {
                    Rectangle()
                        .foregroundStyle(Color(UIColor.tertiarySystemBackground))
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 250, height: 250)
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
            .padding()
        })
    }
}

