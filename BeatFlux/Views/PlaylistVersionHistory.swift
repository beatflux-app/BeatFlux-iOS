//
//  PlaylistVersionHistory.swift
//  BeatFlux
//
//  Created by Ari Reitman on 9/12/23.
//

import SwiftUI

struct PlaylistVersionHistory: View {
    @EnvironmentObject var spotify: Spotify
    @Binding var showPlaylistVersionHistory: Bool
    var playlistInfo: PlaylistInfo
    
    var body: some View {
        
        
        NavigationView {
            List {
                ForEach(0..<playlistInfo.versionHistory.sorted(by: { $0.versionDate > $1.versionDate }).count, id: \.self) { index in
                    NavigationLink(destination: ExportPlaylistView(showExportView: $showPlaylistVersionHistory, playlistToExport: playlistInfo.versionHistory.sorted(by: { $0.versionDate > $1.versionDate })[index].playlist)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Version \(playlistInfo.versionHistory.count - index)")
                                    .font(.headline)
                                
                                Text(playlistInfo.versionHistory.sorted(by: { $0.versionDate > $1.versionDate })[index].versionDate.formatted())
                                    .font(.caption)
                            }

                            Spacer()
                            
                            if index == 0 {
                                Text("Current Version")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)  // Add horizontal padding
                                    .padding(.vertical, 8)  // Add vertical padding
                                    .background(
                                        Capsule()
                                            .foregroundStyle(Color.accentColor)
                                    )
                                



                                
                                    
                            }
                            
                            
                            
                        }
                    }
                    
                    
                }
            }
            .navigationTitle("Version History")
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
            }
        }
    }
}


