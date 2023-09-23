//
//  PlaylistInfoView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 9/21/23.
//

import SwiftUI
import Shimmer
import NukeUI
import SpotifyWebAPI


struct PlaylistInfoView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    var playlistInfo: PlaylistInfo
    
    @State var showExportView: Bool = false
    @State var showPlaylistVersionHistory = false
    @State var showSnapshotAlert = false
    @State var showBanner: Bool = false
    @State var bannerData: BannerModifier.BannerData = BannerModifier.BannerData(imageIcon: Image(systemName: "camera.aperture"),title: "Added Snapshot")
    @State var searchQuery = ""
    @State var isSearchActive: Bool = false
    
    
    var body: some View {
        List {
            ListView(playlistInfo: playlistInfo, searchQuery: $searchQuery)
        }
        .animation(.default, value: searchQuery)
        .searchable(text: $searchQuery)
        .listStyle(.inset)
        .sheet(isPresented: $showPlaylistVersionHistory) {
            
            PlaylistSnapshotView(showPlaylistVersionHistory: $showPlaylistVersionHistory, playlistInfo: playlistInfo)

        }
        .navigationTitle(playlistInfo.playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showSnapshotAlert) {
            Alert(title: Text("Snapshot Limit Reached"), message: Text("You can only save two snapshots at a time!"), dismissButton: .default(Text("Ok")))
        }
        .sheet(isPresented: $showExportView) {
            NavigationView {
                ExportPlaylistView(showExportView: $showExportView, playlistToExport: playlistInfo)
            }
            
        }
        .banner(data: $bannerData, show: $showBanner)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
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
                        }
                         label: {
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

                    
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                }

            }
        }
    }
}

private struct ListView: View {
    var playlistInfo: PlaylistInfo
    @Binding var searchQuery: String
    @Environment(\.isSearching) var isSearching
    
    var body: some View {
        if !isSearching {
            Section {
                HStack {
                    Spacer()
                    AsyncImage(urlString: playlistInfo.playlist.images[0].url.absoluteString) {
                        Rectangle()
                            .aspectRatio(contentMode: .fill)
                            .foregroundColor(.secondary)
                            .shimmering()
                    } content: {
                        Image(uiImage: $0)
                            .resizable()
                            .scaledToFill()
                            
                            .clipped()
                            
                    }
                    .frame(width: (UIScreen.main.bounds.width / 1.8), height: (UIScreen.main.bounds.width / 1.8) )
                    .clipped()
                    .cornerRadius(12)
                    Spacer()
                }
            }
            .listRowSeparator(.hidden)
            .padding(.bottom)
        }
        
        
        Section {
            var filteredTracks: [PlaylistItemContainer<Track>] {
                if searchQuery.isEmpty {
                    return playlistInfo.tracks
                } else {
                    return playlistInfo.tracks.filter { track in
                        (track.item?.name.lowercased().contains(searchQuery.lowercased()) ?? false) ||
                        (track.item?.album?.artists?[0].name.lowercased().contains(searchQuery.lowercased()) ?? false)
                    }
                }
            }
            
            ForEach(filteredTracks, id: \.item?.id) { track in
                HStack {
                    LazyImage(url: track.item?.album?.images?[0].url) { imageState in
                        if let image = imageState.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipped()
                        }
                        else {
                            Rectangle()
                                .foregroundStyle(Color.secondary)
                                .aspectRatio(contentMode: .fill)
                                .redacted(reason: .placeholder)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    ProgressView()
                                }
                            
                        }

                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    VStack(alignment: .leading) {
                        Text(track.item?.name ?? "Unknown")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text(track.item?.album?.artists?[0].name ?? "Unknown")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                     // Assuming name is an optional property in track.item
                   // Text(track.item?.album ?? "Unknown")
                }
            }
            
            
        }
        
        if !isSearching {
            Section {
                VStack(alignment: .leading) {
                    Text("Total Songs: \(playlistInfo.tracks.count)")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    Text("Playlist Created By: \(playlistInfo.playlist.owner?.displayName ?? "Unknown")")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }

            }
            .listRowSeparator(.hidden)
            
        }
    }
}


