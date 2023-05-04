//
//  WebUIView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/4/23.
//

import SwiftUI
import WebKit

// UIViewRepresentable
struct WebUIView: UIViewRepresentable {
    
    var url: URL
    @StateObject var spotifyAuth: SpotifyAuth = SpotifyAuth.shared
    
    func makeCoordinator() -> WebUIViewCoordinator {
        WebUIViewCoordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = false

        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences

        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true

        webView.load(URLRequest(url: url))
        
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {

    }
}

// Coordinator
class WebUIViewCoordinator : NSObject {

    var parent: WebUIView

    public var completionHandler: ((Bool) -> Void)?

    init(_ parent: WebUIView) {
        self.parent = parent
    }
}

// WKNavigationDelegate
extension WebUIViewCoordinator: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard let url = webView.url else { return }
        // Exchange the code for access token
        guard let code = URLComponents(string: url.absoluteString)?.queryItems?.first(where: { $0.value == "code"})?.value else { return }
        parent.spotifyAuth.exchangeCodeForToken(code: code) { success in
            DispatchQueue.main.async {
                self.completionHandler?(success)
            }
        }
    }
}

// WKUIDelegate
extension WebUIViewCoordinator: WKUIDelegate {

}
