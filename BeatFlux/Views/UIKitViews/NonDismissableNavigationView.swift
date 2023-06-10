//
//  NonDismissableNavigationView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 6/5/23.
//


import SwiftUI

struct NonDismissableNavigationView<Content: View>: UIViewControllerRepresentable {
    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    class Coordinator: NSObject, UINavigationControllerDelegate {
        func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
            navigationController.interactivePopGestureRecognizer?.isEnabled = false
        }
    }

    func makeUIViewController(context: Context) -> some UINavigationController {
        let navigationController = UINavigationController(rootViewController: UIHostingController(rootView: content()))
        navigationController.delegate = context.coordinator
        return navigationController
    }

    func updateUIViewController(_ navigationController: UIViewControllerType, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

struct NonDismissableHost<Content: View>: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIHostingController<Content> {
        let hostingController = UIHostingController(rootView: content)
        return hostingController
    }
    
    typealias UIViewControllerType = UIHostingController<Content>
    
    var content: Content

    init(_ content: Content) {
        self.content = content
    }

    class Coordinator: NSObject, UINavigationControllerDelegate {
        func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
            navigationController.interactivePopGestureRecognizer?.isEnabled = false
        }
    }

//    func makeUIViewController(context: Context) -> some UIHostingController<Content> {
//        let hostingController = UIHostingController(rootView: content)
//        return hostingController
//    }

    func updateUIViewController(_ hostingController: UIHostingController<Content>, context: Context) {
        hostingController.rootView = content
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

