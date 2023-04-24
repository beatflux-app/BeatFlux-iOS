//
//  HomeView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/23/23.
//

import SwiftUI


struct HomeView: View {
    
    var size: CGFloat = 170
    
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
                    
                    
                    
                }

                
            }


            
            
            
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
