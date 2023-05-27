//
//  HomeView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/23/23.
//

import SwiftUI


struct HomeView: View {
    @EnvironmentObject var authHandler: AuthHandler
    
    
    var size: CGFloat = 170
    
    var body: some View {
        VStack {
            TopBarView(authHandler: authHandler)
            

            ScrollView {
                
                HStack {
                    Text("Playlists")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.leading)
                
                Grid(alignment: .center, horizontalSpacing: 15, verticalSpacing: 15) {
                    ForEach(0..<10) { index in
                        GridRow {
                            
                            PlaylistGridSquare(size: size)
                            
                            PlaylistGridSquare(size: size)

                            
                        }
                        
                        
                    }
                    
                    
                    
                }

                
            }


            
            
            
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AuthHandler())
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
    @ObservedObject var authHandler: AuthHandler
    
    var body: some View {
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
                authHandler.signOut()
            } label: {
                Circle()
                    .frame(width: 35)
                    .padding(.trailing)
                    .foregroundColor(Color(UIColor.systemGray5))
            }

            
        }
    }
}
