//
//  HomeView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/23/23.
//

import SwiftUI
import Shimmer


struct HomeView: View {
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @EnvironmentObject var spotify: Spotify
    
    @State var showSpotifyLinkPrompt = false
    
    @State var isLoading = false
    @State var showSettings = false
    @State var didScrollUp: Bool = false
    @State var didResetToTop: Bool = true
    @State var showRefreshingIcon: Bool = false
    @State var offset: CGFloat = 0.0
    
    var size: CGFloat = 170
    
    var body: some View {
        VStack {
            TopBarView(showSettings: $showSettings, minimizeTile: didScrollUp)
                .environmentObject(beatFluxViewModel)
            
            ScrollView {
                VStack {
                    //if (showRefreshingIcon) {
                        GeometryReader { proxy in
                            ProgressView()
                                .opacity(showRefreshingIcon ? 1 : 0)
                                .frame(width: proxy.size.width, height: proxy.size.height + max(0, offset))
                                .offset(CGSize(width: 0, height: min(0, -offset)))
                        }
                        .padding(.top, showRefreshingIcon ? 5 : 0)
                        .background(
                            GeometryReader { proxy in
                                let offset = proxy.frame(in: .named("scroll")).minY
                                Color.clear.preference(key: ViewOffsetKey.self, value: offset)
                            }
                        )
                        
                    //}
                    
                    Grid(alignment: .center) {
                        ForEach(0..<10) { index in
                            GridRow {
                                
                                PlaylistGridSquare(size: size)
                                
                                PlaylistGridSquare(size: size)
                                
                                
                            }
                            .shimmering()
                            .padding(.horizontal)
                            .padding(.bottom)
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
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ViewOffsetKey.self) { offset in
                self.offset = offset
                
                if offset <= 0 { didResetToTop = true }
                else { didResetToTop = false }
                
                if offset >= 135 {
                    if !showRefreshingIcon {
                        Task {
                            await fetchData()
                        }
                    }
                    
                }
                
                withAnimation(.easeInOut(duration: 0.2)) {
                    if offset < -135 { didScrollUp = true }
                    else { didScrollUp = false }
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
                    if !userData.account_link_shown && userData.spotify_data?.authorization_manager == nil {
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
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.easeOut(duration: 0.3)) { showRefreshingIcon = true }
        while (!didResetToTop) {
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        
        await beatFluxViewModel.retrieveUserData()
        withAnimation(.easeOut(duration: 0.3)) { showRefreshingIcon = false }
        
        
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(BeatFluxViewModel())
            .environmentObject(Spotify())
    }
}

//TODO: Preference tried to update multiple times (SwiftUI) (FIX ERROR)

private struct ViewOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0.0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

private struct PlaylistGridSquare: View {
    var size: CGFloat
    var body: some View {
        VStack(alignment: .leading) {
            Rectangle()
                .frame(width: size, height: size, alignment: .center)
                .foregroundColor(Color(UIColor.systemGray5))
                .cornerRadius(16)
            VStack(alignment: .leading) {
                Text("Playlist")
                Text("Playist Author")
                
            }
            .redacted(reason: .placeholder)
            .padding(.leading)
            
            
        }
    }
}

private struct TopBarView: View {
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @Binding var showSettings: Bool
    var minimizeTile: Bool
    
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
            HStack {
                Text("Playlists")
                    .font(minimizeTile ? .title3 : .largeTitle)
                    .fontWeight(minimizeTile ? .semibold : .bold)
                    .padding(.leading)
                Spacer()
            }
            
        }
    }
}
