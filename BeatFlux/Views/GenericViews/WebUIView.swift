//
//  WebUIView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/4/23.
//

import SwiftUI
import WebKit
import SpotifyWebAPI
import Combine

// UIViewRepresentable
struct WebUIView: UIViewRepresentable {
    //@StateObject var spotifyAuth: SpotifyAuth = SpotifyAuth.shared
    
    @EnvironmentObject var spotify: Spotify
    @State private var cancellables: Set<AnyCancellable> = []
    
    var url: URL
    
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
    
    func handleURL(_ url: URL) {
            
            // **Always** validate URLs; they offer a potential attack vector into
            // your app.
        guard url.scheme == Spotify.loginCallbackURL.scheme else {
                print("not handling URL: unexpected scheme: '\(url)'")
                return
            }
            
            print("received redirect from Spotify: '\(url)'")
            
            // This property is used to display an activity indicator in `LoginView`
            // indicating that the access and refresh tokens are being retrieved.
            spotify.setIsRetrievingRefreshToken(true)
            
            
            // Complete the authorization process by requesting the access and
            // refresh tokens.
            spotify.api.authorizationManager.requestAccessAndRefreshTokens(
                redirectURIWithQuery: url,
                // This value must be the same as the one used to create the
                // authorization URL. Otherwise, an error will be thrown.
                state: spotify.authorizationState
            )
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                // Whether the request succeeded or not, we need to remove the
                // activity indicator.
                spotify.setAuthorizationValue(false)
                
                
                /*
                 After the access and refresh tokens are retrieved,
                 `SpotifyAPI.authorizationManagerDidChange` will emit a signal,
                 causing `Spotify.authorizationManagerDidChange()` to be called,
                 which will dismiss the loginView if the app was successfully
                 authorized by setting the @Published `Spotify.isAuthorized`
                 property to `true`.

                 The only thing we need to do here is handle the error and show it
                 to the user if one was received.
                 */
                if case .failure(let error) = completion {
                    print("couldn't retrieve access and refresh tokens:\n\(error)")
                    let alertTitle: String
                    let alertMessage: String
                    if let authError = error as? SpotifyAuthorizationError,
                       authError.accessWasDenied {
                        alertTitle = "You Denied The Authorization Request :("
                        alertMessage = ""
                    }
                    else {
                        alertTitle =
                            "Couldn't Authorization With Your Account"
                        alertMessage = error.localizedDescription
                    }

                }
            })
            .store(in: &cancellables)
            
            // MARK: IMPORTANT: generate a new value for the state parameter after
            // MARK: each authorization request. This ensures an incoming redirect
            // MARK: from Spotify was the result of a request made by this app, and
            // MARK: and not an attacker.
            self.spotify.authorizationState = String.randomURLSafe(length: 128)
            
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
        
        self.parent.handleURL(url)
        
        
    }
    
 
}



// WKUIDelegate
extension WebUIViewCoordinator: WKUIDelegate {

}
