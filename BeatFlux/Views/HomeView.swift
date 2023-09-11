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
    @State var showSpotifyPlaylistListView: Bool = false
    
    
    var arrowPullDownMultiplier: CGFloat = 175
    var arrowStartRotationOffset: CGFloat = 20
    
    var size: CGFloat = 170
    
    let fontSizeParameters = ScrollEffectParameters(startOffset: 0, endOffset: -10, newValue: 20, originalValue: 34)
    let opacityPlaylistBackgroundParameters = ScrollEffectParameters(startOffset: 0, endOffset: -10, newValue: 1, originalValue: 0)
    let arrowOpacityParameters = ScrollEffectParameters(startOffset: 10, endOffset: 20, newValue: 1, originalValue: 0)
    let opacityLoadingBackgroundParameters = ScrollEffectParameters(startOffset: 0, endOffset: -10, newValue: 0, originalValue: 1)
    
    var body: some View {
        VStack {
            TopBarView(showSettings: $showSettings, showSpotifyPlaylistListView: $showSpotifyPlaylistListView)
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
                                    .opacity(beatFluxViewModel.isViewModelFullyLoaded ? (!showRefreshingIcon ? arrowOpacityParameters.getValueForOffset(offset: offset) : 0) : 0)
                                
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
                                    
                                    Text("Backups")
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
                                .background(.thickMaterial
                                .opacity(opacityPlaylistBackgroundParameters.getValueForOffset(offset: offset)))
                                
                                
                            }
                            .frame(width: proxy.size.width)
                            .offset(CGSize(width: 0, height: max(0, -offset)))
                            
                            
                            
                        }
                        .padding(.bottom, 55)
                    }
                    .zIndex(1)
                    
                    if beatFluxViewModel.isViewModelFullyLoaded {
                        if beatFluxViewModel.userData != nil {
                            if !spotify.spotifyData.playlists.isEmpty {
                                let playlists = spotify.spotifyData.playlists
                                let chunks = playlists.chunked(size: 2)
                                
                                
                                Grid {
                                    ForEach(0..<chunks.count, id: \.self) { index in
                                    
                                        GridRow(alignment: .top) {
                                            ForEach(chunks[index], id: \.self) { playlist in
                                                PlaylistGridSquare(playlistInfo: playlist)
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
                        else {
                            NoPlaylistsFoundView()
                        }
                    }

                    

                    
                    
                    
                    
                    
                }
                
                .background(
                    GeometryReader { proxy in
                        let offset = proxy.frame(in: .named("scroll")).minY
                        Color.clear.preference(key: ViewOffsetKey.self, value: offset)
                    }
                )
            }
            .overlay {

                VStack(spacing: 20) {
                    LoadingIndicator(color: .accentColor, lineWidth: 4.0)
                        .frame(width: 25, height: 25)
                    
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                        
                }
                .opacity(beatFluxViewModel.isViewModelFullyLoaded ? 0 : 1)
                    
            }
            .scrollDisabled(!beatFluxViewModel.isViewModelFullyLoaded)
            .scrollIndicators(.hidden)
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ViewOffsetKey.self) { offset in
                self.offset = offset
                
                if offset <= 0 { didResetToTop = true }
                else { didResetToTop = false }
                
                if Double(offset - arrowStartRotationOffset) / arrowPullDownMultiplier >= 1.0 {
                    if !showRefreshingIcon && beatFluxViewModel.isViewModelFullyLoaded {
                        Task {
                            await fetchData()
                        }
                    }
                }
                
                
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
        
        spotify.refreshUserPlaylistArray()
        
        await beatFluxViewModel.retrieveUserData()
        await spotify.retrieveSpotifyData()
        
        animateRefreshingIcon(isShowing: false)
    }

    func animateRefreshingIcon(isShowing: Bool) {
        withAnimation(.easeOut(duration: 0.3)) {
            showRefreshingIcon = isShowing
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




private struct ViewOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0.0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

private struct NoPlaylistsFoundView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "questionmark.app.dashed")
                .font(.largeTitle)
            Text("No Backups Found")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top, 5)
            
        }
    }
}

private struct PlaylistGridSquare: View {
    var playlistInfo: PlaylistInfo
    
    @State var showExportView: Bool = false
    
    var body: some View {
        
        
        
        VStack(alignment: .leading) {
            
            if !playlistInfo.playlist.images.isEmpty {
                AsyncImage(urlString: playlistInfo.playlist.images[0].url.absoluteString) {
                    Rectangle()
                        .foregroundStyle(Color(UIColor.secondarySystemGroupedBackground))
                        .aspectRatio(contentMode: .fill)
                        .frame(width: (UIScreen.main.bounds.width / 2) - 25, height: (UIScreen.main.bounds.width / 2) - 25)
                        .redacted(reason: .placeholder)
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
                    .foregroundStyle(Color(UIColor.secondarySystemGroupedBackground))
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
        }))
        .sheet(isPresented: $showExportView) {
            ExportPlaylistView(showExportView: $showExportView, playlistToExport: playlistInfo)
        }
    }
}

private struct TopBarView: View {
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @Binding var showSettings: Bool
    @Binding var showSpotifyPlaylistListView: Bool
    
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
            .overlay(alignment: .trailing) {
                Button {
                    showSpotifyPlaylistListView.toggle()
                } label: {
                    Circle()
                        .frame(width: 35)
                        .foregroundStyle(Color(UIColor.systemGray5))
                        .overlay {
                            Image(systemName: "plus")
                                .fontWeight(.bold)
                                .font(.subheadline)
                        }
                    
                    
                    
                }
                .disabled(!beatFluxViewModel.isViewModelFullyLoaded)
                .padding(.trailing)
            }
            
            .overlay(alignment: .leading) {
                    Button {
                        showSettings.toggle()
                    } label: {
                        Circle()
                            .frame(width: 35)
                            .foregroundStyle(Color(UIColor.systemGray5))
                            .overlay {
                                Image(systemName: "person.fill")
                            }
                    }
                    .disabled(!beatFluxViewModel.isViewModelFullyLoaded)
                    .padding(.leading)
            }
            
            
        }
    }
}
