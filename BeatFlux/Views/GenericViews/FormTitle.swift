//
//  FormTitle.swift
//  BeatFlux
//
//  Created by Ari Reitman on 6/29/23.
//

import SwiftUI

struct FormTitle: ViewModifier {
 
    let font: Font
    let fontWeight: Font.Weight
    
    func body(content: Content) -> some View {
        content
          .foregroundColor(.primary)
          .fontWeight(fontWeight)
          .font(font)
          .textCase(nil)
    }
}
