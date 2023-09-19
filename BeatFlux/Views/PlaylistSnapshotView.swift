//
//  PlaylistVersionHistory.swift
//  BeatFlux
//
//  Created by Ari Reitman on 9/12/23.
//

import SwiftUI

struct PlaylistSnapshotView: View {
    @EnvironmentObject var spotify: Spotify
    @Binding var showPlaylistVersionHistory: Bool
    var playlistInfo: PlaylistInfo
    
    @State var snapshots: [PlaylistSnapshot] = []
    @State var showSnapshotAlert = false
    @State var isLoading = false
    
    var body: some View {
        
        
        NavigationView {
            Form {
                if !isLoading {
                    if snapshots.isEmpty {
                        Text("None")
                            .foregroundStyle(.secondary)
                    }
                    else {
                        ForEach(0..<snapshots.sorted(by: { $0.versionDate > $1.versionDate }).count, id: \.self) { index in
                            NavigationLink(destination: ExportPlaylistView(showExportView: $showPlaylistVersionHistory, playlistToExport: snapshots.sorted(by: { $0.versionDate > $1.versionDate })[index].playlist)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("\(snapshots.sorted(by: { $0.versionDate > $1.versionDate })[index].playlist.tracks.count) Songs")
                                            .font(.headline)
                                            .lineLimit(1)
                                        Text(snapshots.sorted(by: { $0.versionDate > $1.versionDate })[index].versionDate.formatted())
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
                else {
                    VStack(spacing: 15) {
                        ProgressView()
                        Text("Loading...")
                            .foregroundStyle(.secondary)
                    }
                }
                
                
                Section {
                    Button {
                        Task {
                            let snapshots = await self.spotify.getPlaylistSnapshots(playlist: playlistInfo)
                            
                            if snapshots.count < 2 {
                                let snapshot = PlaylistSnapshot(playlist: playlistInfo, versionDate: Date())
                                self.spotify.uploadPlaylistSnapshot(snapshot: snapshot)
                                withAnimation {
                                    self.snapshots.append(snapshot)
                                }
                                
                                
                            }
                            else {
                                showSnapshotAlert = true
                            }
                        }
                    } label: {
                        Text("Create New Snapshot")
                    }
                    .alert(isPresented: $showSnapshotAlert) {
                        Alert(title: Text("Snapshot Error"), message: Text("You can only save two snapshots at a time!"), dismissButton: .default(Text("Ok")))
                    }
                }
                
                
            }
            .navigationTitle("Snapshots")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPlaylistVersionHistory.toggle()
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accentColor)
                    }

                    
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }

        }
        .onAppear {
            Task {
                isLoading = true
                self.snapshots = await spotify.getPlaylistSnapshots(playlist: playlistInfo)
                isLoading = false
                
            }
            
        }

    }
    
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            
            let playlistSnapshot = snapshots[index]
            
            snapshots.remove(at: index)
            Task {
                
                await spotify.deletePlaylistSnapshot(playlist: playlistSnapshot)
            }
        }
    }
}


