//
//  HomeView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/23/23.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
            HStack {
                Image("BeatFluxLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40)
                    .cornerRadius(16)
                
            }
            

            ScrollView {
                HStack {
                    Text("Home")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.leading)
                
                Grid(alignment: .center, horizontalSpacing: 15, verticalSpacing: 15) {
                    ForEach(0..<10) { index in
                        GridRow {
                            Rectangle()
                                .frame(width: 170, height: 170, alignment: .center)
                                .cornerRadius(16)
                            Rectangle()
                                .frame(width: 170, height: 170, alignment: .center)
                                .cornerRadius(16)
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
