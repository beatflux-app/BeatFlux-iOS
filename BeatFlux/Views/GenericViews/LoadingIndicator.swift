//
//  LoadingIndicator.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/30/23.
//

import SwiftUI

struct LoadingIndicator: View {
    
    var showBackground: Bool = false
    
    var size: Double = 70
    var color: Color = .accentColor
    var lineWidth: CGFloat = 0.3
    
    @State private var isLoading: Bool = true
    
    var body: some View {
        ZStack {
            if showBackground {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(.white)
                    .shadow(radius: 5, x: 0, y: 0)
                    .frame(width: size, height: size, alignment: .center)
            }

            Circle()
                .trim(from: 0, to: 0.37)
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundStyle(color)
                .frame(width: size*0.4, alignment: .center)
                .rotationEffect(Angle(degrees: isLoading ? 0 : 360))
                .onAppear {
                    withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        isLoading.toggle()
                    }
                }
        }
    }
}

struct LoadingIndicator_Previews: PreviewProvider {
    static var previews: some View {
        LoadingIndicator()
    }
}
