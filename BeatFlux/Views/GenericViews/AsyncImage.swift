//
//  AsyncImage.swift
//  BeatFlux
//
//  Created by Ari Reitman on 6/21/23.
//

import SwiftUI

struct AsyncImage<Placeholder: View, Content: View>: View {
    @StateObject private var loader: ImageLoader
    private let placeholder: Placeholder
    private let content: (UIImage) -> Content

    init(urlString: String, @ViewBuilder placeholder: () -> Placeholder, @ViewBuilder content: @escaping (UIImage) -> Content) {
        self.placeholder = placeholder()
        _loader = StateObject(wrappedValue: ImageLoader(urlString: urlString))
        self.content = content
    }

    var body: some View {
        ZStack {
            if loader.image != nil {
                content(loader.image!)
            } else {
                placeholder
            }
        }
        .onAppear(perform: loader.load)
    }
}

