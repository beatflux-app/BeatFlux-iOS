import SpotifyWebAPI
import UIKit
import SwiftUI
import Foundation
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
    @Published var userPlaylists: [PlaylistInfo] = []
    @Published var spotifyData: SpotifyDataModel = SpotifyDataModel.defaultData
    
    enum SpotifyError: Error {
        case nilSpotifyData
    }
    
    
    
    private var isUserAuthLoggedIn: Bool = false {
        didSet {
            Task {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.cancellables.removeAll()
                    self.currentUser = nil
                    self.isAuthorized = false
                    self.isRetrievingTokens = false
                    
                    print("SUCCESS: All spotify api cancellables removed successfully")
                    if self.isUserAuthLoggedIn {
                        print(self.cancellables)
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
    }
    


    func retrieveSpotifyData() async {
        do {
            let data = try await DatabaseHandler.shared.getSpotifyData()
            DispatchQueue.main.async { [weak self] in
                self?.spotifyData = data
            }
            
            
            
        }
        catch {
            print("ERROR: Failed to retrieve spotify data: \(error.localizedDescription)")
        }

    }
    
    func uploadSpotifyData() async {
        do {
            try await DatabaseHandler.shared.uploadSpotifyData(from: spotifyData)
        }
        catch {
            print("ERROR: Failed to upload user data: \(error.localizedDescription)")
        }
    }
    
    func uploadSpotifyAuthManager() async {
        do {
            try await DatabaseHandler.shared.uploadSpotifyAuthManager(from: spotifyData)
        }
        catch {
            print("ERROR: Failed to upload spotify auth manager: \(error.localizedDescription)")
        }
    }
    
    func uploadSpecificFieldFromPlaylistCollection(playlist: PlaylistInfo, delete: Bool = false) async {
        do {            
            try await DatabaseHandler.shared.uploadSpecificFieldFromPlaylistCollection(playlist: playlist, delete: delete)
        }
        catch {
            print("ERROR: Failed to update specific field in the database: \(error.localizedDescription)")
        }
    }
    
    func initializeSpotify() {
        
        self.api.apiRequestLogger.logLevel = .trace
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.api.authorizationManagerDidChange
                .receive(on: RunLoop.main)
                .sink(receiveValue: authorizationManagerDidChange)
                .store(in: &self.cancellables)
            
            self.api.authorizationManagerDidDeauthorize
                .receive(on: RunLoop.main)
                .sink(receiveValue: authorizationManagerDidDeauthorize)
                .store(in: &self.cancellables)
        }

        Task {
            do {
                await loadSpotifyData()
                
                guard let authManagerData = try await DatabaseHandler.shared.getSpotifyData().authorization_manager else {
                    print("Did NOT find authorization information in keychain")
                    DispatchQueue.main.async { [weak self] in
                        self?.isSpotifyInitializationLoaded = true
                    }
                    return
                }

                print("Found authorization information in database")
                
                self.api.authorizationManager = authManagerData
                
                refreshUsersPlaylists(options: .libraryPlaylists)
            
                if !self.api.authorizationManager.accessTokenIsExpired() {
                    self.autoRefreshTokensWhenExpired()
                }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
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

                
                
            }
            catch {
                print("ERROR: Unable to get user data from database")
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.isSpotifyInitializationLoaded = true
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
                .ugcImageUpload,
                .userLibraryModify,
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
            
            self.refreshUsersPlaylists(options: .libraryPlaylists)
            
            
        }
            
        // Save the data to the keychain.
        if DatabaseHandler.shared.user != nil {
            spotifyData.authorization_manager = self.api.authorizationManager
            Task {
                await uploadSpotifyAuthManager()
            }
            
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
            Task {
                await uploadSpotifyAuthManager()
            }
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
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.api.currentUserProfile()
                .receive(on: RunLoop.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("ERROR: Couldn't retrieve current user: \(error)")
                        }
                    },
                    receiveValue: { [weak self] user in
                        self?.currentUser = user
                    }
                )
                .store(in: &self.cancellables)
        }

        
    }
    
    
    public func getUserPlaylists(completion: @escaping (PagingObject<Playlist<PlaylistItemsReference>>?) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.api.currentUserPlaylists()
                .extendPages(self.api)
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { _ in },
                      receiveValue: { results in
                    print(self.cancellables)
                    completion(results)
                })
                .store(in: &self.cancellables)
        }

    }
    
    public func retrievePlaylistItem(fetchedPlaylist: Playlist<PlaylistItemsReference>, completion: @escaping (PlaylistInfo) -> Void) {
        self.api.playlistItems(fetchedPlaylist.uri)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("SUCCESS:RETRIEVE_PLAYLIST_ITEM:Finished fetching playlist items")
                case .failure(let error):
                    print("ERROR:RETRIEVE_PLAYLIST_ITEM:Failed to get playlist items: \(error)")
                }
                
            }, receiveValue: { pagingObject in
                completion(PlaylistInfo(playlist: fetchedPlaylist, tracks: pagingObject.items, lastFetched: Date()))
            })
            .store(in: &cancellables)
    }
    
    public func getPlaylistVersionHistory(playlist: PlaylistInfo, completion: @escaping ([priorBackupInfo]) -> ()) {
        DatabaseHandler.shared.getPlaylistsVersionHistory(playlist: playlist) { priorBackUps in
            completion(priorBackUps)
        }
    }
    
    public enum PlaylistRefreshOptions {
        case libraryPlaylists
        case backupPlaylists
        case all
    }
    
    public func refreshUsersPlaylists(options: PlaylistRefreshOptions) {
        // Create a dispatch group
        let group = DispatchGroup()

            self.getUserPlaylists { playlists in
                var playlistsToAdd: [PlaylistInfo] = []
                guard let playlists = playlists else { return }
                
                if (options == .all || options == .libraryPlaylists) {
                    for playlist in playlists.items {
                        
                        // Enter the group before starting the async operation
                        group.enter()
                        
                        var details = PlaylistInfo(playlist: playlist, lastFetched: Date())
                        self.retrievePlaylistItem(fetchedPlaylist: playlist) { info in
                            details.tracks = info.tracks
                            playlistsToAdd.append(details)
                            
                            // Leave the group when the operation is done
                            group.leave()
                        }
                        
                    }
                    
                    // Wait for all the async operations to complete
                    group.notify(queue: .main) {
                        self.userPlaylists = playlistsToAdd
                    }
                }
                
                if (options == .all || options == .backupPlaylists) {
                    for (index, playlist) in self.spotifyData.playlists.enumerated() {
                        if let fetchedPlaylist = playlists.items.first(where: { $0.id == playlist.playlist.id }) {
                            
                            if fetchedPlaylist.snapshotId != playlist.playlist.snapshotId {
                                group.enter()
                                
                                self.convertSpotifyPlaylistToCustom(playlist: fetchedPlaylist, completion: { convertedPlaylist in
                                    DispatchQueue.main.async { [weak self] in
                                        guard let self = self else { return }
                                        self.spotifyData.playlists[index] = convertedPlaylist
                                    }
                                    
                                    
                                    Task { [weak self] in
                                        await self?.uploadSpecificFieldFromPlaylistCollection(playlist: convertedPlaylist, delete: false)
                                        self?.getPlaylistVersionHistory(playlist: convertedPlaylist) { priorBackupInfo in
                                            DispatchQueue.main.async { [weak self] in
                                                self?.spotifyData.playlists[index].versionHistory = priorBackupInfo
                                            }
                                        }
                                    }
                                    
                                    group.leave()
                                    
                                    
                                    
                                    
                                })
                            }
                            else {
                                self.getPlaylistVersionHistory(playlist: playlist) { priorBackupInfo in
                                    DispatchQueue.main.async { [weak self] in
                                        self?.spotifyData.playlists[index].versionHistory = priorBackupInfo
                                    }
                                    
                                }
                            }
                            
                            
                        }
                    }
                    
                }
                
                
                
            }
        
        
    }
    public func backupPlaylist(playlist: PlaylistInfo, completion: @escaping () -> Void) {
        self.getUserPlaylists { fetchedPlaylists in
            guard let fetchedPlaylists else { return }
            
            //if we don't find an existing playlist then add to the list
            guard let item = fetchedPlaylists.items.first(where: { $0.id == playlist.playlist.id }) else {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.spotifyData.playlists.append(playlist)
                    }
                    Task { [weak self] in
                        guard let self = self else { return }
                        await self.uploadSpecificFieldFromPlaylistCollection(playlist: playlist)
                    }
                    completion()
                
                return
            }
            
            //helps save on api calls
            self.convertSpotifyPlaylistToCustom(playlist: item) { details in
                if let index = self.userPlaylists.firstIndex(where: { $0.playlist.id == details.playlist.id }) {
                    DispatchQueue.main.async { [weak self] in
                        self?.userPlaylists[index] = details
                    }
                    
                }
                else {
                    DispatchQueue.main.async { [weak self] in
                        self?.userPlaylists.append(details)
                    }
                    
                }
                
                
                
                DispatchQueue.main.async { [weak self] in
                    self?.spotifyData.playlists.append(details)
                }
                Task { [weak self] in
                    guard let self = self else { return }
                    await self.uploadSpecificFieldFromPlaylistCollection(playlist: playlist)
                }
                completion()
                
            }
        }

    }
    
    public func convertSpotifyPlaylistToCustom(playlist: Playlist<PlaylistItemsReference>, completion: @escaping (PlaylistInfo) -> Void) {
        self.retrievePlaylistItem(fetchedPlaylist: playlist) { fetchedDetails in
            let playlistDetails = PlaylistInfo(playlist: fetchedDetails.playlist, tracks: fetchedDetails.tracks, lastFetched: Date())
            completion(playlistDetails)
        }
    }
    
    public func requestAccessAndRefreshTokens(url: URL, result: @escaping (Bool, Error?) -> Void) {
        enum ErrorTypes: Error {
            case authRequestDenied(String)
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.api.authorizationManager.requestAccessAndRefreshTokens(
                redirectURIWithQuery: url,
                state: self.authorizationState
            )
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                DispatchQueue.main.async { [weak self] in
                    self?.isRetrievingTokens = false
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
            .store(in: &self.cancellables)
        }
        
    }
    
    public func uploadSpotifyPlaylistFromBackup(playlistInfo: PlaylistInfo, playlistName: String, isPublic: Bool, isCollaborative: Bool, description: String, completion: @escaping (Playlist<PlaylistItems>)->Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.api.createPlaylist(for: self.currentUser!.uri, PlaylistDetails(name: playlistName, isPublic: isPublic, isCollaborative: isCollaborative, description: description))
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("SUCCESS: Created playlist from backed up data")
                    case .failure(let error):
                        print("ERROR: Couldn't create playlist based on backed up version:\n\(error)")
                    }
                }, receiveValue: { [weak self] playlistObject in
    //                if !playlistInfo.playlist.images.isEmpty {
    //                    self.uploadSpotifyPlaylistImage(playlist: playlistObject.uri, image: playlistInfo.playlist.images[0])
    //                }
                    self?.uploadTracksToPlaylist(exportedPlaylist: playlistInfo, newPlaylistURI: playlistObject.uri) {
                        completion(playlistObject)
                    }

                    
                   
                })
                .store(in: &self.cancellables)
        }
        
    }
    
    
    
    public func uploadSpotifyPlaylistImage(playlist: SpotifyURIConvertible, image: SpotifyImage) {
        
        guard let url = URL(string: "https://i.scdn.co/image/ab67706c0000bebbdce8ac805e4a1a9469083388") else {
            print("Invalid URL")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
            } else if let data = data {
                let newUIImage: UIImage? = UIImage(data: data)
                if let validImage = newUIImage, let jpegData = validImage.jpegData(compressionQuality: 0.5) {
                    let base64EncodedData = jpegData.base64EncodedData()
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        
                        self.api.uploadPlaylistImage(playlist, imageData: base64EncodedData)
                            .receive(on: RunLoop.main)
                            .sink { completion in
                                switch completion {
                                case .finished: break
                                case .failure(let error):
                                    print("ERROR: Unable to upload playlist image: \(error)")
                                }
                            }
                            .store(in: &self.cancellables)
                    }

                }
            }
        }
        

        task.resume()
        
            
        
        
    }
    
    public func uploadTracksToPlaylist(exportedPlaylist: PlaylistInfo, newPlaylistURI: SpotifyURIConvertible, result: @escaping ()->Void) {
        
        print(exportedPlaylist.playlist.name)
        
        let uris = self.retrieveTrackURIFromPlaylist(playlist: exportedPlaylist)
        print(uris)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.api.addToPlaylist(newPlaylistURI, uris: uris)
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished: break
                    case .failure(let error):
                        print("ERROR: Unable to upload songs to playlist: \(error)")
                        result()
                    }
                    
                    
                }, receiveValue: { returnValue in
                    result()
                })
                .store(in: &self.cancellables)
        }
        
    }
    
    
    public func unfollowPlaylist(uri: SpotifyURIConvertible) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.api.unfollowPlaylistForCurrentUser(uri)
                .receive(on: RunLoop.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        print("SUCCESS: Unfollowed playlist")
                    case .failure(let error):
                        print("ERROR: Unable to unfollow playlist: \(error)")
                    }
                }
                .store(in: &self.cancellables)
        }
        

    }
    
    public func retrieveTrackURIFromPlaylist(playlist: PlaylistInfo) -> [SpotifyURIConvertible] {
        var uris: [SpotifyURIConvertible] = []

        
        for track in playlist.tracks {
            if let uri = track.item?.uri {
                print("valid uri")
                uris.append(uri)
                print("SUCCESS: Valid URI \(uri)")
            }
            else {
                print("ERROR: Not valid URI")
            }
            
        }
        
        
        
        return uris
    }
    
    
}
