//
//  WebView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/29/23.
//
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    var onCallbackURL: ((URL) -> Void)?
    
    func makeUIView(context: Context) -> WKWebView  {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        uiView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            if url.scheme == "beatflux" {
                parent.onCallbackURL?(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}
