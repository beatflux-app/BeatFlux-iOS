//
//  SettingsTextLabel_Element.swift
//  BeatFlux
//
//  Created by Ari Reitman on 6/4/23.
//

import SwiftUI

struct SettingsTextLabel_Element<Content> : View where Content : View {
    var content: () -> Content
    var text: String
    var placeholderText: String
    
    public init(text: String, placeholderText: String, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.text = text
        self.placeholderText = placeholderText
    }
    
    public var body: some View {
        ModifiedContent(content: self.content(), modifier: SettingsTextLabel_Modifier(text: text, placeholderText: placeholderText))
    }
}

private struct SettingsTextLabel_Modifier: ViewModifier {
    
    var text: String
    var placeholderText: String
    
    func body(content: Content)-> some View {
        VStack {
            ZStack(alignment: .leading) {
                
                
                Text(placeholderText)
                    .foregroundColor(text.isEmpty ? .secondary : .accentColor)
                    .offset(y: text.isEmpty ? 0 : -25)
                    .scaleEffect(text.isEmpty ? 1 : 0.8, anchor: .leading)
                
                content
                
            }
            
            
            .animation(.default, value: text.isEmpty)
        }
    }
}
