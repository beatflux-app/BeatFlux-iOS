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
                    VStack(spacing: 15) {
                        HStack {
                            Spacer()
                            ProgressView()
                            Text("Loading...")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }

                    }
                }
                
                Section {
                    Button {
                        if !isUploading {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            Task {
                            //isLoading = true
                            print("pressed")
                            
                                snapshots = await self.spotify.getPlaylistSnapshots(playlist: playlistInfo)
                                
                                if snapshots.count < 2 {
                                    withAnimation {
                                        isUploading = true
                                    }
                                    
                
                                    
                                    let snapshot = PlaylistSnapshot(id: UUID().uuidString, playlist: playlistInfo, versionDate: Date())
                                    self.spotify.uploadPlaylistSnapshot(snapshot: snapshot)

                                    withAnimation {
                                        self.snapshots.append(snapshot)
                                    }
                                    

                                    withAnimation {
                                        isUploading = false
                                    }
                                    
                                    
                                    
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
        .onChange(of: snapshots) { value in
            print(value.count)
        }
        .onAppear {
            Task {
                withAnimation {
                    isLoading = true
                }
                
                self.snapshots = await spotify.getPlaylistSnapshots(playlist: playlistInfo)
                withAnimation {
                    isLoading = false
                }
                
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
                
                await spotify.deletePlaylistSnapshot(playlist: playlistSnapshot)
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


