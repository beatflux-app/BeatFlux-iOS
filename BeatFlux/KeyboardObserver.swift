//
//  KeyboardObserver.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/27/23.
//

import SwiftUI
import Combine

class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0

    var keyboardWillChange = NotificationCenter.default
        .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
        .map { ($0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0 }

    var cancellable: AnyCancellable?

    init() {
        cancellable = keyboardWillChange.sink { [weak self] height in
            self?.keyboardHeight = height
        }
    }

    deinit {
        cancellable?.cancel()
    }
}
