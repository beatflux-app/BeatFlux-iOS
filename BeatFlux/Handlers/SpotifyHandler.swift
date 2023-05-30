import SpotifyWebAPI
import UIKit
import SwiftUI
import Foundation
import KeychainAccess
import Combine

final class Spotify: ObservableObject {
    private static let clientId: String = {
        if let clientId = ProcessInfo.processInfo
                .environment["CLIENT_ID"] {
            return clientId
        }
        fatalError("Could not find 'CLIENT_ID' in environment variables")
    }()
    
    private static let clientSecret: String = {
        if let clientSecret = ProcessInfo.processInfo
                .environment["CLIENT_SECRET"] {
            return clientSecret
        }
        fatalError("Could not find 'CLIENT_SECRET' in environment variables")
    }()
    
    let authorizationManagerKey = "authorizationManager"
    
    let loginCallbackURL = URL(
        string: "beatflux://login-callback"
    )!
    
    var authorizationState = String.randomURLSafe(length: 128)
    
    @Published var isAuthorized = false
    @Published var isRetrievingTokens = false
    @Published var currentUser: SpotifyUser? = nil
    
    let keychain = Keychain(service: "com.beatflux.BeatFlux")
    
    let api = SpotifyAPI(
        authorizationManager: AuthorizationCodeFlowManager(
            clientId: Spotify.clientId,
            clientSecret: Spotify.clientSecret
        )
    )
    
    var cancellables: Set<AnyCancellable> = []

    var refreshTokensCancellable: AnyCancellable? = nil
    
    let refreshTokensQueue = DispatchQueue(label: "refreshTokens")
    
    init() {
        self.api.apiRequestLogger.logLevel = .trace
        
        self.api.authorizationManagerDidChange
            .receive(on: RunLoop.main)
            .sink(receiveValue: authorizationManagerDidChange)
            .store(in: &cancellables)
        
        self.api.authorizationManagerDidDeauthorize
            .receive(on: RunLoop.main)
            .sink(receiveValue: authorizationManagerDidDeauthorize)
            .store(in: &cancellables)
        
        if let authManagerData = keychain[data: self.authorizationManagerKey] {
            do {
                let authorizationManager = try JSONDecoder().decode(
                    AuthorizationCodeFlowManager.self,
                    from: authManagerData
                )
                print("found authorization information in keychain")
                
                self.api.authorizationManager = authorizationManager
                                
                if !self.api.authorizationManager.accessTokenIsExpired() {
                    self.autoRefreshTokensWhenExpired()
                }
                self.api.authorizationManager.refreshTokens(
                    onlyIfExpired: true
                )
                .sink(receiveCompletion: { completion in
                    switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            print(
                                "Spotify.init: couldn't refresh tokens:\n\(error)"
                            )
                    }
                })
                .store(in: &self.cancellables)
            }
            catch {
                print("could not decode authorizationManager from data:\n\(error)")
            }
        }
        else {
            print("did NOT find authorization information in keychain")
        }
    }
    
    private func autoRefreshTokensWhenExpired() {
        guard let expirationDate = self.api.authorizationManager.expirationDate else {
            return
        }
        
        let refreshDate = expirationDate.addingTimeInterval(-115)
        
        let refreshDelay = refreshDate.timeIntervalSince1970 - Date().timeIntervalSince1970

        self.refreshTokensCancellable = Result.Publisher(())
            .delay(
                for: .seconds(refreshDelay),
                scheduler: self.refreshTokensQueue
            )
            .flatMap {
                // this method should be called 1 minute and 55 seconds before
                // the access token expires.
                return self.api.authorizationManager.refreshTokens(
                    onlyIfExpired: true
                )
            }
            .sink(receiveCompletion: { completion in
                print("autoRefreshTokensWhenExpired completion: \(completion)")
            })
    }
    
    func authorize() -> URL {
        let url = api.authorizationManager.makeAuthorizationURL(
            redirectURI: self.loginCallbackURL,
            showDialog: true,
            // This same value **MUST** be provided for the state parameter of
            // `authorizationManager.requestAccessAndRefreshTokens(redirectURIWithQuery:state:)`.
            // Otherwise, an error will be thrown.
            state: authorizationState,
            scopes: [
                .userReadPlaybackState,
                .userModifyPlaybackState,
                .playlistModifyPrivate,
                .playlistModifyPublic,
                .userLibraryRead,
                .userLibraryModify,
                .userReadRecentlyPlayed
            ]
        )!
        
        // You can open the URL however you like. For example, you could open
        // it in a web view instead of the browser.
        // See https://developer.apple.com/documentation/webkit/wkwebview
        
        return url
        //UIApplication.shared.open(url)
        
    }
    
    func authorizationManagerDidChange() {
        
        DispatchQueue.main.async {
            self.isAuthorized = self.api.authorizationManager.isAuthorized()
        }
            
        
        print(
            "Spotify.authorizationManagerDidChange: isAuthorized:",
            self.isAuthorized
        )
        
        self.autoRefreshTokensWhenExpired()
        
        self.retrieveCurrentUser()
        
        do {
            // Encode the authorization information to data.
            let authManagerData = try JSONEncoder().encode(
                self.api.authorizationManager
            )
            
            // Save the data to the keychain.
            Task {
                let userData = try await DatabaseHandler.shared.getUserData()
                if let userData = userData {
                    
                }
            }
            
            keychain[data: self.authorizationManagerKey] = authManagerData
            print("did save authorization manager to keychain")
        } catch {
            print(
                "couldn't encode authorizationManager for storage " +
                    "in keychain:\n\(error)"
            )
        }
        
    }
    
    func authorizationManagerDidDeauthorize() {
        withAnimation() {
            self.isAuthorized = false
        }
        
        self.currentUser = nil
        self.refreshTokensCancellable = nil
        
        do {
            try keychain.remove(self.authorizationManagerKey)
            print("did remove authorization manager from keychain")
            
        } catch {
            print(
                "couldn't remove authorization manager " +
                "from keychain: \(error)"
            )
        }
    }
    
    func retrieveCurrentUser(onlyIfNil: Bool = true) {
        if onlyIfNil && self.currentUser != nil {
            return
        }

        guard self.isAuthorized else { return }

        self.api.currentUserProfile()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("couldn't retrieve current user: \(error)")
                    }
                },
                receiveValue: { user in
                    self.currentUser = user
                }
            )
            .store(in: &cancellables)
        
    }
    
    
    public func getUserPlaylists(completion: @escaping (PagingObject<Playlist<PlaylistItemsReference>>?) -> Void) {

        self.api.currentUserPlaylists()
            .extendPages(self.api)
            .sink(receiveCompletion: { _ in },
              receiveValue: { results in
                  completion(results)
              })
            .store(in: &cancellables)
    }
    
    
}
