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
                self.cancellables.removeAll()
                
                
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
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
            print("Finished")
        }
        catch {
            print("ERROR: Failed to update specific field in the database: \(error.localizedDescription)")
        }
    }
    
    func initializeSpotify() {
        
        self.api.apiRequestLogger.logLevel = .trace

        self.api.authorizationManagerDidChange
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: authorizationManagerDidChange)
            .store(in: &self.cancellables)
        
        self.api.authorizationManagerDidDeauthorize
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: authorizationManagerDidDeauthorize)
            .store(in: &self.cancellables)
        

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
                Task {
                    await refreshUsersPlaylists(options: .libraryPlaylists)
                }
                
            
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
            
            Task {
                await self.refreshUsersPlaylists(options: .libraryPlaylists)
            }
            
            
            
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
        DispatchQueue.main.async { [weak self] in
            self?.currentUser = nil
            self?.refreshTokensCancellable = nil
            self?.userPlaylists = []
        }

        
        if DatabaseHandler.shared.user != nil {
            DispatchQueue.main.async { [weak self] in
                self?.spotifyData.authorization_manager = nil
            }
            
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

            self.api.currentUserProfile()
                .receive(on: DispatchQueue.main)
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
    
    public func getUserPlaylists() async throws -> PagingObject<Playlist<PlaylistItemsReference>> {
        return try await withCheckedThrowingContinuation { continuation in
            self.api.currentUserPlaylists()
                .extendPages(self.api)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main) // Switch back to the main queue for the result
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("ERROR: Error while getting users playlists \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }, receiveValue: { results in
                    continuation.resume(returning: results)
                })
                .store(in: &self.cancellables)
        }
    }

    
    
    public func retrievePlaylistItem(fetchedPlaylist: Playlist<PlaylistItemsReference>) async throws -> PlaylistInfo {
        return try await withCheckedThrowingContinuation { continuation in
            self.api.playlistItems(fetchedPlaylist.uri)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("ERROR: Error while getting playlist item \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }, receiveValue: { pagingObject in
                    continuation.resume(returning: PlaylistInfo(playlist: fetchedPlaylist, tracks: pagingObject.items, lastFetched: Date()))
                })
                .store(in: &self.cancellables)
        }
    }




    public func getPlaylistVersionHistory(playlist: PlaylistInfo) async -> [priorBackupInfo] {
        return await DatabaseHandler.shared.getPlaylistsVersionHistory(playlist: playlist)
    }
    
    public enum PlaylistRefreshOptions {
        case libraryPlaylists
        case backupPlaylists
        case all
    }
    
    public func refreshUsersPlaylists(options: PlaylistRefreshOptions) async {

        do {
            let playlists = try await self.getUserPlaylists()
            
            
            
            var playlistsToAdd: [PlaylistInfo] = []
            
            if (options == .all || options == .libraryPlaylists) {
                for playlist in playlists.items {
                    var details = PlaylistInfo(playlist: playlist, lastFetched: Date())
                    let playlistInfo = try await self.retrievePlaylistItem(fetchedPlaylist: playlist)
                    
                    details.tracks = playlistInfo.tracks
                    playlistsToAdd.append(details)
                }

                DispatchQueue.main.async {
                    self.userPlaylists = playlistsToAdd
                }
                
                
            }
            
            if (options == .all || options == .backupPlaylists) {
                for (index, playlist) in self.spotifyData.playlists.enumerated() {
                    if let fetchedPlaylist = playlists.items.first(where: { $0.id == playlist.playlist.id }) {
                        
                        if fetchedPlaylist.snapshotId != playlist.playlist.snapshotId {
                            
                            let convertedPlaylist = await self.convertSpotifyPlaylistToCustom(playlist: fetchedPlaylist)
                            
                            guard let convertedPlaylist = convertedPlaylist else { return }
                            
                            DispatchQueue.main.async { [weak self] in
                                self?.spotifyData.playlists[index] = convertedPlaylist
                            }
                            
                        
                            await self.uploadSpecificFieldFromPlaylistCollection(playlist: convertedPlaylist, delete: false)
                            let priorBackupInfo = await self.getPlaylistVersionHistory(playlist: convertedPlaylist)
                            DispatchQueue.main.async { [weak self] in
                                self?.spotifyData.playlists[index].versionHistory = priorBackupInfo
                            }
                            
                            
                        }
                        else {
                            let priorBackupInfo = await self.getPlaylistVersionHistory(playlist: playlist)
                            DispatchQueue.main.async { [weak self] in
                                self?.spotifyData.playlists[index].versionHistory = priorBackupInfo
                            }
                        }
                        
                    }
                }

            }
        }
        catch {
            print("ERROR: Error while refreshing users playlist \(error.localizedDescription)")
        }
    }
    
    public func backupPlaylist(playlist: PlaylistInfo) async {
        do {
            let fetchedPlaylists = try await self.getUserPlaylists()
                
            //if we don't find an existing playlist then add to the list
            guard let item = fetchedPlaylists.items.first(where: { $0.id == playlist.playlist.id }) else {
                DispatchQueue.main.async { [weak self] in
                    self?.spotifyData.playlists.append(playlist)
                }
                Task { [weak self] in
                    await self?.uploadSpecificFieldFromPlaylistCollection(playlist: playlist)
                }
                
                return
            }
            
            //helps save on api calls
            let details = await self.convertSpotifyPlaylistToCustom(playlist: item)
            
            guard let details = details else { return }
        
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
            
                
            
        }
        catch {
            print("ERROR: Error while backing up playlists \(error.localizedDescription)")
        }
        

    }
    
    public func convertSpotifyPlaylistToCustom(playlist: Playlist<PlaylistItemsReference>) async -> PlaylistInfo? {
        do {
            let fetchedDetails = try await self.retrievePlaylistItem(fetchedPlaylist: playlist)
            let playlistDetails = PlaylistInfo(playlist: fetchedDetails.playlist, tracks: fetchedDetails.tracks, lastFetched: Date())
            return playlistDetails
        }
        catch {
            print("ERROR: Error occured when converting spotify playlist to custom playlist \(error.localizedDescription)")
            return nil
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
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { completion in
            DispatchQueue.main.async { [weak self] in
                self?.isRetrievingTokens = false
            }

            switch completion {
            case .finished:
                
                result(true, nil)
                
            case .failure(let error):
                print("ERROR: Couldn't retrieve access and refresh tokens:\n\(error)")
                if let authError = error as? SpotifyAuthorizationError, authError.accessWasDenied {
                    
                    result(false, ErrorTypes.authRequestDenied("Authorization request denied"))
                    
                }
                else {
                    
                    result(false, error)
                    
                }
            }

        })
        .store(in: &self.cancellables)
        
        
    }
    
    public func uploadSpotifyPlaylistFromBackup(playlistInfo: PlaylistInfo, playlistName: String, isPublic: Bool, isCollaborative: Bool, description: String) async throws -> Playlist<PlaylistItems> {

        
        return try await withCheckedThrowingContinuation { continuation in
            self.api.createPlaylist(for: self.currentUser!.uri, PlaylistDetails(name: playlistName, isPublic: isPublic, isCollaborative: isCollaborative, description: description))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("SUCCESS: Created playlist from backed up data")
                    case .failure(let error):
                        print("ERROR: Couldn't create playlist based on backed up version:\n\(error)")
                        continuation.resume(throwing: error)
                    }
                }, receiveValue: { playlistObject in
                    Task {
                        do {
                            try await self.uploadTracksToPlaylist(exportedPlaylist: playlistInfo, newPlaylistURI: playlistObject.uri)
                            continuation.resume(returning: playlistObject)
                        } catch {
                            continuation.resume(throwing: error)
                        }
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
                    
                    DispatchQueue.global(qos: .background).async { [weak self] in
                        guard let self = self else { return }
                        
                        self.api.uploadPlaylistImage(playlist, imageData: base64EncodedData)
                            .receive(on: DispatchQueue.main)
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
    
    public func uploadTracksToPlaylist(exportedPlaylist: PlaylistInfo, newPlaylistURI: SpotifyURIConvertible) async throws {
        
        let uris = self.retrieveTrackURIFromPlaylist(playlist: exportedPlaylist)

        var cancellables = Set<AnyCancellable>()

        try await withCheckedThrowingContinuation { continuation in
            self.api.addToPlaylist(newPlaylistURI, uris: uris)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished: break
                    case .failure(let error):
                        print("ERROR: Unable to upload songs to playlist: \(error)")
                        continuation.resume(throwing: error)
                    }
                }, receiveValue: { returnValue in
                    // Use 'returnValue' if you want
                    continuation.resume()
                })
                .store(in: &cancellables)
        }
    }
    
    
    public func unfollowPlaylist(uri: SpotifyURIConvertible) {
        self.api.unfollowPlaylistForCurrentUser(uri)
            .receive(on: DispatchQueue.main)
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
