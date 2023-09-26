//
//  PlaylistVersionHistory.swift
//  BeatFlux
//
//  Created by Ari Reitman on 9/12/23.
//

import SwiftUI

struct PlaylistSnapshotView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var spotify: Spotify
    @Binding var showPlaylistVersionHistory: Bool
    var playlistInfo: PlaylistInfo
    
    @State var snapshots: [PlaylistSnapshot] = []
    @State var showSnapshotAlert = false
    @State var isLoading = false
    @State var isUploading = false
    @State var isPresentingConfirm = false
    @State var isRefreshing: Bool = false
    @State var arrowRotation: Double = 0
    
    var body: some View {
        
        
        NavigationView {
            Form {
                
                
                if !isLoading {
                    Section {
                        if snapshots.isEmpty {
                            Text("None")
                                .foregroundStyle(.secondary)
                        }
                        else {

                        
                        
                            ForEach(snapshots.sorted(by: { $0.versionDate > $1.versionDate })) { snapshot in
                                NavigationLink(destination: ExportPlaylistView(showExportView: $showPlaylistVersionHistory, playlistToExport: snapshot.playlist)) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("\(snapshot.playlist.tracks.count) Songs")
                                                .font(.headline)
                                                .lineLimit(1)
                                            Text(snapshot.versionDate.formatted())
                                                .font(.caption)
                                        }
                                        .padding(.trailing)

                                        Spacer()


                                        
                                        
                                        
                                    }
                                }
                                
                                
                                
                            }
                            .onDelete(perform: delete(at:))
                        }
                        
                    
                    }
                }
                else {
                    HStack(spacing: 15) {
                        ProgressView()
                        Text("Loading...")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                
                Section {
                    Button {
                        if !isUploading {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            Task {
                            //isLoading = true
                                
                                snapshots = await self.spotify.getPlaylistSnapshots(playlist: playlistInfo, location: .cloud)
                                
                                
                                if snapshots.count < 2 {
                                    
                                    isUploading = true
                                    
                                    
                
                                    
                                    let snapshot = PlaylistSnapshot(id: UUID().uuidString, playlist: playlistInfo, versionDate: Date())
                                    await self.spotify.uploadPlaylistSnapshot(snapshot: snapshot, playlistInfo: playlistInfo)

                                    withAnimation {
                                        self.snapshots.append(snapshot)
                                    }
                                    

                                   
                                    isUploading = false
                                    
                                    
                                    
                                    
                                }
                                else {
                                    showSnapshotAlert = true
                                }
                            }

                            //isLoading = false
                        }
                    } label: {
                        HStack {
                            Text("Create New Snapshot")
                            Spacer()
                            if isUploading {
                                ProgressView()
                            }
                            
                            
                        }
                        
                    }
                    .disabled(snapshots.count >= 2 || isUploading || isLoading)
                    .alert(isPresented: $showSnapshotAlert) {
                        Alert(title: Text("Snapshot Limit Reached"), message: Text("You can only save two snapshots at a time!"), dismissButton: .default(Text("Ok")))
                    }
                    
                }
                footer: {
                   Text("\(2 - snapshots.count) of 2 Snapshots Remaining")
               }
                
                Section {
                    HStack {
                        Spacer()
                        VStack(alignment: .center, spacing: 12) {
                            Text("Don't see your snapshots?")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button {
                                if !isRefreshing {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    Task {
                                        toggleRefreshing()
                                        
                                        self.snapshots = await spotify.getPlaylistSnapshots(playlist: playlistInfo, location: .cloud)
                                        toggleRefreshing()
                                    }
                                }

                                
                            } label: {
                                HStack(spacing: 15) {
                                    Text("Refresh")
                                    Image(systemName: "arrow.clockwise")
                                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                        .animation(
                                            isRefreshing ?
                                                Animation.linear(duration: 1)
                                                .repeatForever(autoreverses: false) : .default, value: isRefreshing
                                        )
                                        .onAppear {
                                            if isRefreshing {
                                                arrowRotation = 360
                                            }
                                        }
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding([.horizontal])
                                .padding(.vertical, 5)
                                .background {
                                    Capsule()
                                        .foregroundColor(.accentColor)
                                }
                            }

                        }
                        Spacer()
                    }
                    
                }
                .listRowBackground(Color.clear)
                

                    
                
                
                
                
                
            }
            .navigationTitle("Snapshots")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPlaylistVersionHistory.toggle()
                    } label: {
                        dismissButton
                    }

                    
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }

        }
        .onAppear {
            //if let index = spotify.spotifyData.playlists.firstIndex(where:  { $0.playlist.id == playlistInfo.playlist.id }) {
                //if spotify.spotifyData.playlists[index].snapshots.isEmpty {
            
            if let cache = spotify.cachedSnapshots[playlistInfo.playlist.id] {
                self.snapshots = cache
            }
            else {
                Task {
                    
                    isLoading = true
                    
                    
                    self.snapshots = await spotify.getPlaylistSnapshots(playlist: playlistInfo, location: .cloud)
                    
//                        DispatchQueue.main.async {
//
//
//                            spotify.spotifyData.playlists[index].snapshots = snapshots
//
//
//                        }
                    
                    isLoading = false
                    
                    
                }
            }
                    
              //  }
            //}
        }

    }
    
    private func toggleRefreshing() {
        if isRefreshing {
            // Already refreshing. Set to a full circle.
            let remaining = 360 - (arrowRotation.truncatingRemainder(dividingBy: 360))
            withAnimation(Animation.linear(duration: remaining / 360)) {
                arrowRotation += remaining
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + remaining / 360) {
                isRefreshing = false
            }
        } else {
            // Start refreshing
            isRefreshing = true
            withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                arrowRotation += 360
            }
        }
    }
    
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            withAnimation {
                isUploading = true
            }
            
            let playlistSnapshot = snapshots[index]
            DispatchQueue.main.async {
                snapshots.remove(at: index)
            }
            
            Task {
                
                await spotify.deletePlaylistSnapshot(playlist: playlistSnapshot, playlistInfo: playlistInfo)
                withAnimation {
                    isUploading = false
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


