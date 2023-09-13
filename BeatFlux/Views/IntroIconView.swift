//
//  IntroIconView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 9/12/23.
//

import SwiftUI

struct IntroIconView: View {
    @State private var scale: CGFloat = 1.0
        
        var body: some View {
            VStack {
                Spacer()
                Image("BeatFluxLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .scaleEffect(scale)
                    .onAppear {
                        let animation = Animation.easeInOut(duration: 0.3)
                            .repeatForever(autoreverses: true)
                        withAnimation(animation) {
                            scale = 1.1
                        }
                    }
                Spacer()
            }
        }
}

struct IntroIconView_Previews: PreviewProvider {
    static var previews: some View {
        IntroIconView()
    }
}
