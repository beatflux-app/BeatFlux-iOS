//
//  RedactedView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 6/1/23.
//

import SwiftUI
import Shimmer

struct RedactedView: View {
    var isRedacted: Bool
    var text: Text
    
    
    var body: some View {
        if isRedacted {
            text
                .redacted(reason: .placeholder)
                .shimmering()
        } else {
            text
        }
    }
}

struct RedactedView_Previews: PreviewProvider {
    static var previews: some View {
        RedactedView(isRedacted: true, text: Text("Test"))
    }
}
