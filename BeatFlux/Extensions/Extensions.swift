//
//  Extensions.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/26/23.
//

import UIKit

extension UINavigationController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
    }
}
