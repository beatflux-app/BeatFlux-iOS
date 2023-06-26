//
//  ExitButtonStyle.swift
//  BeatFlux
//
//  Created by Ari Reitman on 6/26/23.
//

import SwiftUI

struct ExitButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    var buttonSize: Double = 30
    var symbolScale: Double = 0.416
    
    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        
        return configuration.label
        
            .padding()
            .background(
                Circle()
                    .fill(Color(white: colorScheme == .dark ? 0.19 : 0.93))
                    //.brightness(isPressed ? 0.1 : 0) // Aclara el color cuando está presionado
                    .frame(width: buttonSize, height: buttonSize)
            )
            .overlay(
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .font(Font.body.weight(.bold))
                    .scaleEffect(symbolScale)
                    .foregroundColor(Color(white: colorScheme == .dark ? 0.62 : 0.51))
                    
            )
            .buttonStyle(PlainButtonStyle())
            .opacity(isPressed ? 0.18 : 1)

    }
}
