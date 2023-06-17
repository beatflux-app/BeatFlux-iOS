//
//  LoadingIndicator.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/30/23.
//

import SwiftUI

struct LoadingIndicator: View {
    var color: Color = .accentColor
    var lineWidth: CGFloat = 0.3
    
    @State private var isLoading: Bool = true
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.37)
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundStyle(color)
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
