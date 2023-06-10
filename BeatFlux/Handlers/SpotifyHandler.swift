import SpotifyWebAPI
import UIKit
import SwiftUI
import Foundation
import KeychainAccess
import FirebaseCore
import FirebaseAuth
import Combine

final class Spotify: ObservableObject {
    private static let clientId: String = {
        if let clientId = Bundle.main.infoDictionary?["CLIENT_ID"] as? String {
            return clientId
        }
        fatalError("Could not find 'CLIENT_ID' in environment variables")
    }()
    
    private static let clientSecret: String = {
        if let clientSecret = Bundle.main.infoDictionary?["CLIENT_SECRET"] as? String {
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
    
    
    private var isUserAuthLoggedIn: Bool = false {
        didSet {
            Task {
                DispatchQueue.main.async {
                    self.currentUser = nil
                    self.isAuthorized = false
                    self.isRetrievingTokens = false
                    self.cancellables.removeAll()
                    print("SUCCESS: All spotify api cancellables removed successfully")
                    if self.isUserAuthLoggedIn {
                        self.initializeSpotify()
                    }
                }

                
            }
            
            
        }
    }
    
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
        Auth.auth().addStateDidChangeListener { auth, user in
            if let _ = user {
                self.isUserAuthLoggedIn = true
            } else {
                self.isUserAuthLoggedIn = false
            }
        }
        
        if self.isUserAuthLoggedIn {
            initializeSpotify()
        }
        
        
        
    }
    
    func initializeSpotify() {
        print(Spotify.clientId)
        
        self.api.apiRequestLogger.logLevel = .trace
        
        self.api.authorizationManagerDidChange
            .receive(on: RunLoop.main)
            .sink(receiveValue: authorizationManagerDidChange)
            .store(in: &cancellables)
        
        self.api.authorizationManagerDidDeauthorize
            .receive(on: RunLoop.main)
            .sink(receiveValue: authorizationManagerDidDeauthorize)
            .store(in: &cancellables)
        Task {
            do {
                guard let authManagerData = try await DatabaseHandler.shared.getUserData()?.spotify_data?.authorization_manager else {
                    print("Did NOT find authorization information in keychain")
                    return
                }

                print("Found authorization information in database")
                
                self.api.authorizationManager = authManagerData
            
            
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
                                "ERROR: Spotify.init: couldn't refresh tokens:\n\(error)"
                            )
                    }
                })
                .store(in: &self.cancellables)
                    

            }
            catch {
                print("ERROR: Unable to get user data from database")
            }
            
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
            print(self.isAuthorized)
            
            print(
                "Spotify.authorizationManagerDidChange: isAuthorized:",
                self.isAuthorized
            )
            
            self.autoRefreshTokensWhenExpired()
            
            self.retrieveCurrentUser()
        }
            
        // Save the data to the keychain.
        Task {
            do {
                let userData = try await DatabaseHandler.shared.getUserData()
                if var userData = userData {
                    userData.spotify_data?.authorization_manager = self.api.authorizationManager
                    try await DatabaseHandler.shared.uploadUserData(from: userData)
                    print("SUCCESS: Did save authorization manager to database")
                }
                else {
                    print("ERROR: User data is invalid")
                }
            } catch {
                print(
                    "ERROR: Couldn't encode authorizationManager for storage " +
                        "in keychain:\n\(error)"
                )
            }
        }
            
        
        
    }
    
    func authorizationManagerDidDeauthorize() {
        withAnimation() {
            self.isAuthorized = false
        }
        
        self.currentUser = nil
        self.refreshTokensCancellable = nil
        
        
        
        Task {
            do {
                guard var userModel = try await DatabaseHandler.shared.getUserData() else {
                    print("ERROR: Unable to retrive user data from the database")
                    return
                }
                
                userModel.spotify_data?.authorization_manager = nil
                try await DatabaseHandler.shared.uploadUserData(from: userModel)
                print("SUCCESS: Did remove authorization manager from database")
                
            }
            catch {
                print(
                    "ERROR: Couldn't remove authorization manager " +
                    "from database: \(error)"
                )
            }
        }
    }
    
    func retrieveCurrentUser(onlyIfNil: Bool = true) {
        if onlyIfNil && self.currentUser != nil {
            return
        }

        guard self.isAuthorized else {
            print("User is not authorized")
            return
        }

        self.api.currentUserProfile()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("ERROR: Couldn't retrieve current user: \(error)")
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
