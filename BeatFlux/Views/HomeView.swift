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
    
    var hasReachedMaxPoint: Bool {
        return offset > 0
    }
    
    var size: CGFloat = 170
    
    var body: some View {
        VStack {
            TopBarView(showSettings: $showSettings, minimizeTile: didScrollUp)
                .environmentObject(beatFluxViewModel)

            ScrollViewReader { scrollView in
                ScrollView {
                        VStack {
                            if (showRefreshingIcon) {
                                GeometryReader { proxy in
                                    
                                    ProgressView()
                                        .frame(width: proxy.size.width,
                                               height: proxy.size.height + max(0, offset))
                                        .offset(CGSize(width: 0, height: min(0, -offset)))
                                    
                                    
                                }
                                .padding(.top, 5)
                                .background(
                                    GeometryReader { proxy in
                                        let offset = proxy.frame(in: .named("scroll")).minY
                                        Color.clear.preference(key: ViewOffsetKey.self, value: offset)
                                    }
                                )
                                
                            }

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
                .onChange(of: offset) { newValue in
                    if showRefreshingIcon { didResetToTop = newValue <= 0 }
                    else { didResetToTop = true }
                    
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ViewOffsetKey.self) { offset in
                    self.offset = offset
                    if offset >= 135 {
                        if didResetToTop {
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
        await beatFluxViewModel.retrieveUserData()
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
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

private struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
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
