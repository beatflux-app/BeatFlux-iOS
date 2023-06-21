//
//  HomeView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/23/23.
//

import SwiftUI
import SpotifyWebAPI
import Combine

struct HomeView: View {
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @EnvironmentObject var spotify: Spotify
    
    @State var showSpotifyLinkPrompt = false
    
    @State var isLoading = false
    @State var showSettings = false
    @State var didResetToTop: Bool = true
    @State var showRefreshingIcon: Bool = false
    @State var offset: CGFloat = 0.0
    var arrowPullDownMultiplier: CGFloat = 100
    var arrowStartRotationOffset: CGFloat = 30
    
    var size: CGFloat = 170
    
    let fontSizeParameters = ScrollEffectParameters(startOffset: 0, endOffset: -10, newValue: 20, originalValue: 34)
    let opacityPlaylistBackgroundParameters = ScrollEffectParameters(startOffset: 0, endOffset: -10, newValue: 1, originalValue: 0)
    let arrowOpacityParameters = ScrollEffectParameters(startOffset: 30, endOffset: 40, newValue: 1, originalValue: 0)
    let opacityLoadingBackgroundParameters = ScrollEffectParameters(startOffset: 0, endOffset: -10, newValue: 0, originalValue: 1)
    
    var body: some View {
        VStack {
            TopBarView(showSettings: $showSettings)
                .environmentObject(beatFluxViewModel)
            
            ScrollView {
                VStack {
                    ZStack {
                        GeometryReader { proxy in
                            ZStack(alignment: .top) {
                                Image(systemName: "arrow.up")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .rotationEffect(.degrees(offset > arrowStartRotationOffset ? max(180, 180 + min((Double(offset - arrowStartRotationOffset) / arrowPullDownMultiplier) * 180.0, 180)) : 180), anchor: .center)
                                    .foregroundStyle(Color.accentColor)
                                    .opacity(!showRefreshingIcon ? arrowOpacityParameters.getValueForOffset(offset: offset) : 0)
                                
                                LoadingIndicator(color: .accentColor, lineWidth: 4.0)
                                    .frame(width: 25, height: 25)
                                    .opacity(showRefreshingIcon ? 1 : 0)
                                
                            }
                            .opacity(opacityLoadingBackgroundParameters.getValueForOffset(offset: offset))
                            .padding(.top, 5)
                            .frame(width: proxy.size.width)
                            .offset(CGSize(width: 0, height: -offset))
                            
                            VStack(spacing: 0) {
                                Rectangle()
                                    .foregroundStyle(Color(UIColor.systemBackground).opacity(opacityPlaylistBackgroundParameters.getValueForOffset(offset: offset)))
                                    .frame(height: 20)
                                
                                
                                HStack {
                                    
                                    Text("Playlists")
                                        .font(.system(size: fontSizeParameters.getValueForOffset(offset: offset)))
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                                                        
                                    Spacer()
                                    
                                    LoadingIndicator(color: .accentColor, lineWidth: 3.0)
                                        .frame(width: 15, height: 15)
                                        .opacity(offset < -10 ? (showRefreshingIcon ? 1 : 0) : 0)
                                    
                                }
                                
                                .padding(.horizontal)
                                .padding(.vertical, 3)
                                .background(.bar.opacity(opacityPlaylistBackgroundParameters.getValueForOffset(offset: offset)))
                                
                                
                            }
                            .frame(width: proxy.size.width)
                            .offset(CGSize(width: 0, height: max(0, -offset)))
                            
                            
                            
                        }
                        .padding(.bottom, 55)
                    }
                    .zIndex(1)
                    
                    
                    if let userData = beatFluxViewModel.userData {
                        if !userData.spotify_data.playlists.isEmpty {
                            let columns = [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ]
                            LazyVGrid(columns: columns, spacing: 20) {
                                
                                ForEach(userData.spotify_data.playlists.indices, id: \.self) { index in
                                    PlaylistGridSquare(playlist: userData.spotify_data.playlists[index].playlist)
                                }
                                
                            }
                            .padding(.horizontal)
                        }
                        else {
                            NoPlaylistsFoundView()
                        }
                    }
                    else {
                        NoPlaylistsFoundView()
                    }

                    
                    
                    
                    
                    
                }
                
                .background(
                    GeometryReader { proxy in
                        let offset = proxy.frame(in: .named("scroll")).minY
                        Color.clear.preference(key: ViewOffsetKey.self, value: offset)
                    }
                )
            }
            .scrollIndicators(.hidden)
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ViewOffsetKey.self) { offset in
                self.offset = offset
                
                if offset <= 0 { didResetToTop = true }
                else { didResetToTop = false }
                
                if Double(offset - arrowStartRotationOffset) / arrowPullDownMultiplier >= 1.0 {
                    if !showRefreshingIcon {
                        Task {
                            await fetchData()
                        }
                    }
                }
                
                
            }
            
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
                    if !userData.account_link_shown && userData.spotify_data.authorization_manager == nil {
                        showSpotifyLinkPrompt = true
                    }
                }
            }
        })
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(showSettings: $showSettings)
        }
        
    }

    func fetchData() async {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        animateRefreshingIcon(isShowing: true)
        
        while (!didResetToTop) {
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        
        if spotify.isAuthorized {
            spotify.getUserPlaylists { optionalPlaylists in
                guard let playlists = optionalPlaylists else {
                    print("No playlists")
                    return
                }
                
                for fetchedPlaylist in playlists.items {
                    handleFetchedPlaylist(fetchedPlaylist)
                }
            }
        }
        
        
        
        await beatFluxViewModel.retrieveUserData()
        
        animateRefreshingIcon(isShowing: false)
    }

    func animateRefreshingIcon(isShowing: Bool) {
        withAnimation(.easeOut(duration: 0.3)) {
            showRefreshingIcon = isShowing
        }
    }

    func handleFetchedPlaylist(_ fetchedPlaylist: Playlist<PlaylistItemsReference>) {
        if let foundPlaylist = beatFluxViewModel.userData?.spotify_data.playlists.first(where: { $0.playlist.id == fetchedPlaylist.id}) {
            handleFoundPlaylist(foundPlaylist: foundPlaylist, fetchedPlaylist: fetchedPlaylist)
        } else {
            retrieveAndAppendPlaylistItem(fetchedPlaylist: fetchedPlaylist)
        }
    }

    func handleFoundPlaylist(foundPlaylist: PlaylistDetails, fetchedPlaylist: Playlist<PlaylistItemsReference>) {
        if foundPlaylist.playlist.snapshotId != fetchedPlaylist.snapshotId {
            spotify.retrievePlaylistItem(fetchedPlaylist: fetchedPlaylist) { playlistDetails in
                updatePlaylistDetails(fetchedPlaylist: fetchedPlaylist, playlistDetails: playlistDetails)
            }
        } else {
            print("Already updated")
        }
    }

    func retrieveAndAppendPlaylistItem(fetchedPlaylist: Playlist<PlaylistItemsReference>) {
        spotify.retrievePlaylistItem(fetchedPlaylist: fetchedPlaylist) { playlistDetails in
            DispatchQueue.main.async {
                beatFluxViewModel.userData?.spotify_data.playlists.append(playlistDetails)
            }
        }
    }

    func updatePlaylistDetails(fetchedPlaylist: Playlist<PlaylistItemsReference>, playlistDetails: PlaylistDetails) {
        if let index = beatFluxViewModel.userData?.spotify_data.playlists.firstIndex(where: { $0.playlist.id == fetchedPlaylist.id}) {
            DispatchQueue.main.async {
                beatFluxViewModel.userData?.spotify_data.playlists[index] = playlistDetails
            }
        } else {
            DispatchQueue.main.async {
                beatFluxViewModel.userData?.spotify_data.playlists.append(playlistDetails)
            }
        }
    }
    
}


struct ScrollEffectParameters {
    var startOffset: CGFloat
    var endOffset: CGFloat
    var newValue: CGFloat
    var originalValue: CGFloat

    func getValueForOffset(offset: CGFloat) -> CGFloat {
        if startOffset <= endOffset {
            // Handle positive scrolling (offset increases)
            if offset < startOffset {
                return originalValue
            } else if offset > endOffset {
                return newValue
            } else {
                let value = originalValue + ((offset - startOffset) / (endOffset - startOffset)) * (newValue - originalValue)
                return value
            }
        } else {
            // Handle negative scrolling (offset decreases)
            if offset > startOffset {
                return originalValue
            } else if offset < endOffset {
                return newValue
            } else {
                let value = originalValue - ((startOffset - offset) / (startOffset - endOffset)) * (originalValue - newValue)
                return value
            }
        }
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(BeatFluxViewModel())
            .environmentObject(Spotify())
    }
}


private struct NoPlaylistsFoundView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "questionmark.app.dashed")
                .font(.largeTitle)
            Text("No Playlists Found")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top, 5)
            
        }
    }
}

private struct ViewOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0.0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

private struct PlaylistGridSquare: View {
    var playlist: Playlist<PlaylistItemsReference>
    
    var body: some View {
        
        VStack(alignment: .leading) {
            AsyncImage(url: playlist.images[0].url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .foregroundStyle(Color(UIColor.secondarySystemGroupedBackground))
                    .aspectRatio(contentMode: .fill)
                    .redacted(reason: .placeholder)
            }
            .clipped()
            .cornerRadius(16)
            
            VStack(alignment: .leading) {
                Text(playlist.name)
                    .fontWeight(.semibold)
                Text(playlist.owner?.displayName ?? "Unknown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
            }
            
            
        }
        
        
    }
}

private struct TopBarView: View {
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @Binding var showSettings: Bool
    
    var body: some View {
        VStack {
            HStack {
                Image("BeatFluxLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40)
                    .cornerRadius(16)
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                Circle()
                    .frame(width: 35)
                    .padding(.leading)
                    .foregroundColor(Color(UIColor.systemGray5))
            }
            
            .overlay(alignment: .trailing) {
                Button {
                    showSettings.toggle()
                } label: {
                    Circle()
                        .frame(width: 35)
                        .padding(.trailing)
                        .foregroundColor(Color(UIColor.systemGray5))
                }
                .disabled(!beatFluxViewModel.isViewModelFullyLoaded)
                
                
            }
            
            
        }
    }
}
