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
    
    @Published var isSpotifyInitializationLoaded = false
    @Published var isAuthorized = false
    
    @Published var isRetrievingTokens = false
    @Published var currentUser: SpotifyUser? = nil
    @Published var userPlaylists: [PlaylistDetails] = []
    @Published var spotifyData: SpotifyDataModel = SpotifyDataModel.defaultData {
        didSet {
            Task {
                do {
                    try await uploadSpotifyData()
                } catch {
                    print("ERROR: Failed to upload user data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    enum SpotifyError: Error {
        case nilSpotifyData
    }
    
    
    
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
    
    func loadSpotifyData() async {
        await retrieveSpotifyData()
        DispatchQueue.main.async {
            self.isSpotifyInitializationLoaded = true
        }
    }
    


    func retrieveSpotifyData() async {
        do {
            let data = try await DatabaseHandler.shared.getSpotifyData()
            DispatchQueue.main.async {
                self.spotifyData = data
            }
            
        }
        catch {
            print("ERROR: Failed to retrieve user data: \(error.localizedDescription)")
        }

    }
    
    func uploadSpotifyData() async throws {
        do {
            try await DatabaseHandler.shared.uploadSpotifyData(from: spotifyData)
        }
        catch {
            print("ERROR: Failed to upload user data: \(error.localizedDescription)")
        }
    }
    
    func initializeSpotify() {
        
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
                await loadSpotifyData()
                
                guard let authManagerData = try await DatabaseHandler.shared.getSpotifyData().authorization_manager else {
                    print("Did NOT find authorization information in keychain")
                    return
                }

                print("Found authorization information in database")
                
                self.api.authorizationManager = authManagerData
                
                refreshUserPlaylistArray()
            
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
                .userReadRecentlyPlayed,
                .playlistReadPrivate,
                .playlistReadCollaborative,
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

            print(
                "Spotify.authorizationManagerDidChange: isAuthorized:",
                self.isAuthorized
            )
            
            self.autoRefreshTokensWhenExpired()
            
            self.retrieveCurrentUser()
            
            self.refreshUserPlaylistArray()
            
            
        }
            
        // Save the data to the keychain.
        if DatabaseHandler.shared.user != nil {
            spotifyData.authorization_manager = self.api.authorizationManager
        }
        else {
            print("ERROR: Unable to save user, user is nil")
        }
        
    }
    
    func authorizationManagerDidDeauthorize() {
        withAnimation() {
            self.isAuthorized = false
        }
        
        self.currentUser = nil
        self.refreshTokensCancellable = nil
        self.userPlaylists = []
        
        if DatabaseHandler.shared.user != nil {
            spotifyData.authorization_manager = nil
        }
        else {
            print("ERROR: Unable to save user, user is nil")
        }
    }
    
    func retrieveCurrentUser(onlyIfNil: Bool = false) {
        if onlyIfNil && self.currentUser != nil {
            return
        }

        guard self.isAuthorized else {
            print("ERROR: User is not authorized")
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
    
    public func retrievePlaylistItem(fetchedPlaylist: Playlist<PlaylistItemsReference>, completion: @escaping (PlaylistDetails) -> Void) {
        self.api.playlistItems(fetchedPlaylist.uri)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("SUCCESS:RETRIEVE_PLAYLIST_ITEM:Finished fetching playlist items")
                case .failure(let error):
                    print("ERROR:RETRIEVE_PLAYLIST_ITEM:Failed to get playlist items: \(error)")
                }
                
            }, receiveValue: { pagingObject in
                completion(PlaylistDetails(playlist: fetchedPlaylist, tracks: pagingObject.items, lastFetched: Date()))
            })
            .store(in: &cancellables)
    }
    
    public func refreshUserPlaylistArray() {
        self.getUserPlaylists { playlists in
            
            var playlistsToAdd: [PlaylistDetails] = []
            
            if let playlists = playlists {
                for playlist in playlists.items {
                    
                    var details = PlaylistDetails(playlist: playlist, lastFetched: Date())
                    self.retrievePlaylistItem(fetchedPlaylist: playlist) { info in
                        details.tracks = info.tracks
                    }
                    playlistsToAdd.append(details)
                }
            }
            
            DispatchQueue.main.async {
                self.userPlaylists = playlistsToAdd
            }
            

        }
    }
    
    public func backupPlaylist(playlist: PlaylistDetails, completion: @escaping () -> Void) {
        self.getUserPlaylists { fetchedPlaylists in
            guard let fetchedPlaylists else { return }
            
            guard let item = fetchedPlaylists.items.first(where: { $0.id == playlist.playlist.id }) else {
                DispatchQueue.main.async {
                    self.spotifyData.playlists.append(playlist)
                    completion()
                }
                return
            }
            
            //helps save on api calls
            if playlist.playlist.snapshotId != item.snapshotId {
                print("Different version")
                
                    self.convertSpotifyPlaylistToCustom(playlist: item) { details in
                        if let index = self.userPlaylists.firstIndex(where: { $0.playlist.id == details.playlist.id }) {
                            DispatchQueue.main.async {
                                self.userPlaylists[index] = details
                            }
                            
                        }
                        else {
                            DispatchQueue.main.async {
                                self.userPlaylists.append(details)
                            }
                            
                        }
                        
                        DispatchQueue.main.async {
                            self.spotifyData.playlists.append(details)
                            completion()
                        }
                    }
                }
                else {
                    DispatchQueue.main.async {
                        self.spotifyData.playlists.append(playlist)
                        completion()
                    }
                }
        }

    }
    
    public func convertSpotifyPlaylistToCustom(playlist: Playlist<PlaylistItemsReference>, completion: @escaping (PlaylistDetails) -> Void) {
        self.retrievePlaylistItem(fetchedPlaylist: playlist) { fetchedDetails in
            let playlistDetails = PlaylistDetails(playlist: fetchedDetails.playlist, tracks: fetchedDetails.tracks, lastFetched: Date())
            
            completion(playlistDetails)

        }
    }
    
    public func requestAccessAndRefreshTokens(url: URL, result: @escaping (Bool, Error?) -> Void) {
        enum ErrorTypes: Error {
            case authRequestDenied(String)
        }
        
        self.api.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: url,
            state: self.authorizationState
        )
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { completion in
            DispatchQueue.main.async {
                self.isRetrievingTokens = false
            }

            switch completion {
            case .finished:
                DispatchQueue.main.async {
                    result(true, nil)
                }
            case .failure(let error):
                print("ERROR: Couldn't retrieve access and refresh tokens:\n\(error)")
                if let authError = error as? SpotifyAuthorizationError, authError.accessWasDenied {
                    DispatchQueue.main.async {
                        result(false, ErrorTypes.authRequestDenied("Authorization request denied"))
                    }
                }
                else {
                    DispatchQueue.main.async {
                        result(false, error)
                    }
                }
            }

        })
        .store(in: &cancellables)
    }
    
    
    
}
