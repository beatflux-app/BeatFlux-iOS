//
//  SpotifyHandler.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/3/23.
//

import Foundation
import SwiftUI
import SpotifyWebAPI
import Combine

final class SpotifyAuth: ObservableObject {
    static let shared = SpotifyAuth()
    
    let spotify = SpotifyAPI(authorizationManager: AuthorizationCodeFlowPKCEManager(clientId: "75706410f2a24590b90d6f2e443aac42"))
    
    @AppStorage(Constants.id_code_challenge) private var _codeChallenge: String = ""
    @AppStorage("access_token") private var accessToken: String = ""
    @AppStorage("refresh_token") private var refreshToken: String = ""
    
    
    var cancellables = Set<AnyCancellable>()
     
    
    
    struct Constants {
        static let codeVerifier = String.randomURLSafe(length: 128)
        static let state: String = String.randomURLSafe(length: 128)
        static let redirectURI: String = "https://beatflux.app"
        static let id_code_challenge = "id_code_challenge"
    }
    
    var codeChallenge: String {
        get {
            if _codeChallenge.isEmpty {
                DispatchQueue.main.async {
                    self._codeChallenge = String.makeCodeChallenge(codeVerifier: Constants.codeVerifier)
                }
                
            }
            return _codeChallenge
        }
        set {
            _codeChallenge = newValue
        }
    }
    
    public var signInURL: URL? {
        return spotify.authorizationManager.makeAuthorizationURL(
            redirectURI: URL(string: Constants.redirectURI)!,
            codeChallenge: codeChallenge,
            state: Constants.state,
            scopes: [
                .playlistModifyPrivate,
                .userModifyPlaybackState,
                .playlistReadCollaborative,
                .userReadPlaybackPosition
            ]
        )!
    }
    
    func requestAccessAndRefreshTokens() {
        spotify.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: signInURL!,
            // Must match the code verifier that was used to generate the
            // code challenge when creating the authorization URL.
            codeVerifier: Constants.codeVerifier,
            // Must match the value used when creating the authorization URL.
            state: Constants.state
        )
        .sink(receiveCompletion: { completion in
            switch completion {
                case .finished:
                    print("successfully authorized")
                case .failure(let error):
                    if let authError = error as? SpotifyAuthorizationError, authError.accessWasDenied {
                        print("The user denied the authorization request")
                    }
                    else {
                        print("couldn't authorize application: \(error)")
                    }
            }
        })
        .store(in: &cancellables)
    }
    
    func checkAndRefreshTokens() {
        if !accessToken.isEmpty, !refreshToken.isEmpty {
//            spotify.authorizationManager.accessToken = accessToken
//            spotify.authorizationManager.refreshToken = refreshToken

            spotify.authorizationManager.refreshTokens(onlyIfExpired: true)
                .sink(receiveCompletion: { completion in
                    switch completion {
                        case .finished:
                            print("Tokens refreshed")
                            // Save updated access token
                            self.accessToken = self.spotify.authorizationManager.accessToken!
                        case .failure(let error):
                            print("Error refreshing tokens: \(error)")
                            // Clear saved tokens
                            self.accessToken = ""
                            self.refreshToken = ""
                    }
                })
                .store(in: &cancellables)
        }
    }

    
}
