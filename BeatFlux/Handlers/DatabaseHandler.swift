//
//  DatabaseHandler.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/20/23.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import Combine
import CombineFirebaseFirestore
import FirebaseDatabase
import SpotifyWebAPI

final class DatabaseHandler {
    
    let firestore = Firestore.firestore()
    let database = Database.database()
    private var cancellables = Set<AnyCancellable>()
    
    
    static let shared = DatabaseHandler()
    
    var user: User? {
        return Auth.auth().currentUser
    }
    
    private enum UserError: Error {
        case nilUser
    }
    
    
    public enum FirestoreFieldUpdateErrors: Error {
        case couldNotConvertToJSON
    }
    
    func initializeUser(firstName: String, lastName: String) {
        guard let user = user else { return }
        
        firestore.collection("users")
            .document(user.uid)
            .setData(from: UserModel(first_name: firstName, last_name: lastName, email: user.email, is_using_dark: false), merge: true)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("ERROR: Initializing user data failed: \(error)")
                    }
                },
                receiveValue: {
                    print("SUCCESS: Initialization user data was successfully initialized to database")
                }
            )
            .store(in: &cancellables)
    }
    
    func initializeSpotifyData() {
        guard let user = user else { return }
        
        firestore.collection("users")
            .document(user.uid)
            .setData(from: SpotifyDataModel(authorization_manager: nil, playlists: []), merge: true)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("ERROR: Initializing spotify data failed: \(error)")
                    }
                },
                receiveValue: {
                    print("SUCCESS: Initialization Spotify data was successfully initialized to database")
                }
            )
            .store(in: &cancellables)
        
    }
    
    func updateFieldIfNil<T>(docRef: DocumentReference, document: DocumentSnapshot?, fieldName: String, defaultValue: T) {
        guard let data = document?.data() else {
            print("ERROR: Document data is invalid")
            return
        }
        if data[fieldName] == nil {
            docRef.updateData([fieldName: defaultValue]) { err in
                if let err = err {
                    print("ERROR: Error updating document: \(err)")
                } else {
                    print("SUCCESS: Document successfully updated")
                }
            }
        }
    }
    
    func getUserData() async throws -> UserModel? {
        guard let user = user else {
            print("ERROR: Failed to get data from database because the user is nil")
            throw UserError.nilUser
        }
        return try await withCheckedThrowingContinuation { continuation in
            let docRef = firestore.collection("users").document(user.uid)
            
            
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    self.updateFieldIfNil(docRef: docRef, document: document, fieldName: "first_name", defaultValue: UserModel.defaultData.first_name)
                    self.updateFieldIfNil(docRef: docRef, document: document, fieldName: "last_name", defaultValue: UserModel.defaultData.last_name)
                    self.updateFieldIfNil(docRef: docRef, document: document, fieldName: "is_using_dark", defaultValue: UserModel.defaultData.is_using_dark)
                    self.updateFieldIfNil(docRef: docRef, document: document, fieldName: "account_link_shown", defaultValue: UserModel.defaultData.account_link_shown)
                    
                    let firstName = document.get("first_name") as? String ?? UserModel.defaultData.first_name
                    let last_name = document.get("last_name") as? String ?? UserModel.defaultData.last_name
                    let email = document.get("email") as? String
                    let isUsingDark = document.get("is_using_dark") as? Bool ?? UserModel.defaultData.is_using_dark
                    let accountLinkShown = document.get("account_link_shown") as? Bool ?? UserModel.defaultData.account_link_shown
                    
                    var spotifyDataModel: SpotifyDataModel = SpotifyDataModel(authorization_manager: nil, playlists: [])
                    
                    if let spotifyData = document.get("spotify_data") as? [String: Any] {
                        
                        if let authorizationManager = spotifyData["authorization_manager"] as? String {
                            do {
                                let decoder = JSONDecoder()
                                let authManager = try decoder.decode(AuthorizationCodeFlowManager.self, from: Data(authorizationManager.utf8))
                                
                                spotifyDataModel.authorization_manager = authManager
                                
                            } catch {
                                print("ERROR: decoding AuthorizationCodeFlowManager: \(error)")
                            }
                        }
                        
                        if let playlistsData = spotifyData["playlists"] as? String {
                            do {
                                let decoder = JSONDecoder()
                                let playlists = try decoder.decode([PlaylistInfo].self, from: Data(playlistsData.utf8))
                                spotifyDataModel.playlists = playlists
                            } catch {
                                print("ERROR: decoding playlist details: \(error)")
                            }
                        }
                        
                        
                    }
                    
                    
                    let returnValue = UserModel(
                        first_name: firstName,
                        last_name: last_name,
                        email: email,
                        is_using_dark: isUsingDark,
                        account_link_shown: accountLinkShown)
                    
                    continuation.resume(returning: returnValue)
                } else {
                    print("Document does not exist, initlizing data (ERROR HANDLED)")
                    self.initializeUser(firstName: UserModel.defaultData.first_name, lastName: UserModel.defaultData.first_name)
                    continuation.resume(throwing: error ?? UserError.nilUser)
                }
            }
        }
    }
    
    func getSpotifyData() async throws -> SpotifyDataModel {
        guard let user = user else {
            print("ERROR: Failed to get data from database because the user is nil")
            throw UserError.nilUser
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let docRef = firestore.collection("users").document(user.uid)
            
            docRef.getDocument { [weak self] (document, error) in
                guard let self = self else { return }
                if let document = document, document.exists {
                    var spotifyData: SpotifyDataModel = SpotifyDataModel.defaultData
                    
                    do {
                        let decoder = JSONDecoder()
                        
                        if let authorizationManager = document.get("authorization_manager") as? String {
                            let authManager = try decoder.decode(AuthorizationCodeFlowManager.self, from: Data(authorizationManager.utf8))
                            spotifyData.authorization_manager = authManager
                        }
                        
                        // Reference to the playlists sub-collection
                        let playlistsCollection = self.firestore.collection("users").document(user.uid).collection("playlists")
                        
                        let group = DispatchGroup()
                        
                        var playlists: [PlaylistInfo] = []
                        
                        playlistsCollection.getDocuments { (querySnapshot, error) in
                            if let error = error {
                                print("ERROR: \(error)")
                                continuation.resume(throwing: error)
                                return
                            }

                            for document in querySnapshot!.documents {
                                if let playlistData = document.get("data") as? String {
                                    let playlist = try? decoder.decode(PlaylistInfo.self, from: Data(playlistData.utf8))

                                    if var playlist = playlist {
                                        // Enter the group before starting the async operation
                                        group.enter()

                                        self.getPlaylistsVersionHistory(playlist: playlist) { versionHistory in
                                            playlist.versionHistory = versionHistory
                                            playlists.append(playlist)

                                            // Leave the group when the operation is done
                                            group.leave()
                                        }
                                    }
                                }
                            }

                            // Wait for all the async operations to complete
                            group.notify(queue: .main) {
                                spotifyData.playlists = playlists
                                continuation.resume(returning: spotifyData)
                            }
                        }
                        
                    } catch {
                        print("ERROR: decoding data: \(error)")
                        continuation.resume(throwing: error)
                    }
                    
                } else {
                    print("HANDLED ERROR: Document does not exist, initializing data")
                    self.initializeUser(firstName: UserModel.defaultData.first_name, lastName: UserModel.defaultData.first_name)
                    continuation.resume(throwing: error ?? UserError.nilUser)
                }
            }
        }
    }
    
    func getPlaylistsVersionHistory(playlist: PlaylistInfo, completion: @escaping([priorBackupInfo]) -> ()) {
        guard let user = user else { 
            completion([])
            return
        }
        let versionHistoryCollection = firestore.collection("users").document(user.uid).collection("playlists").document(playlist.playlist.id).collection("versionHistory")
        let decoder = JSONDecoder()
        var versionHistoryArray: [priorBackupInfo] = []
        let group = DispatchGroup()
        
        group.enter()
        
        versionHistoryCollection.getDocuments { (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else {
                group.leave()
                return
            }
            for document in querySnapshot.documents {
                if let versionHistroy = document.get("data") as? String {
                    let backup = try? decoder.decode(priorBackupInfo.self, from: Data(versionHistroy.utf8))
                    if let backup = backup {
                        versionHistoryArray.append(backup)
                    }
                }
            }
            
            group.leave()
        }
        group.notify(queue: .main) {
            print("SUCCESS: All version histories for playlist: \(playlist.playlist.id) have been fetched: (\(versionHistoryArray.count))")
            
            completion(versionHistoryArray)
        }
        
    }
    
    
    public func updateFirestoreField<T: Encodable>(collection: String, documentId: String, field: String, newValue: T?) throws {
        
        
        let documentRef = firestore.collection(collection).document(documentId)
        
        if let newValue = newValue {
            do {
                let authManagerEncodedManager = try JSONEncoder().encode(newValue)
                if let authDataString = String(data: authManagerEncodedManager, encoding: .utf8) {
                    documentRef.updateData([
                        "fieldData.\(field)": authDataString
                    ]) { err in
                        if let err = err {
                            print("ERROR: Error updating document: \(err)")
                        } else {
                            print("SUCCESS: Firestore field successfully updated")
                        }
                    }
                }
                else {
                    throw FirestoreFieldUpdateErrors.couldNotConvertToJSON
                }
                
                
            }
            catch {
                throw error
            }
        }
        else {
            documentRef.updateData([
                "fieldData.\(field)": FieldValue.delete()
            ]) { err in
                if let err = err {
                    print("Error deleting field: \(err)")
                } else {
                    print("SUCCESS: Field successfully deleted")
                }
            }
        }
        
        
        
    }
    
    func uploadSpecificFieldFromPlaylistCollection(playlist: PlaylistInfo, delete: Bool = false) async throws {
        guard let user = user else {
            throw UserError.nilUser
        }
        
        let playlistsCollection = firestore.collection("users").document(user.uid).collection("playlists")
        let versionHistoryCollection = firestore.collection("users").document(user.uid).collection("playlists").document(playlist.playlist.id).collection("versionHistory")
        
        
        
        // Upload playlist individually
        let playlistEncoded = try JSONEncoder().encode(playlist)
        guard let playlistString = String(data: playlistEncoded, encoding: .utf8) else {
            return
        }
        if delete {
            return try await withCheckedThrowingContinuation { continuation in
                versionHistoryCollection.getDocuments { snapshot, error in
                    guard let snapshot = snapshot else { return }
                    
                    for document in snapshot.documents {
                        document.reference.delete() { error in
                            if let error = error {
                                print("ERROR: Deleting field failed: \(error)")
                                continuation.resume(throwing: error)
                            } else {
                                print("SUCCESS: Field was successfully deleted")
                            }
                        }
                    }
                }
                
                playlistsCollection.document(playlist.playlist.id).delete() { error in
                    if let error = error {
                        print("ERROR: Deleting field failed: \(error)")
                        continuation.resume(throwing: error)
                    } else {
                        print("SUCCESS: Field was successfully deleted")
                        continuation.resume()
                    }
                }
            }
        }
        
        
        // Use playlist.id as the document ID for easier querying later
        return try await withCheckedThrowingContinuation { continuation in
            playlistsCollection.document(playlist.playlist.id).setData(["data": playlistString], merge: true) { error in
                if let error = error {
                    print("ERROR: Writing data failed: \(error)")
                    continuation.resume(throwing: error)
                } else {
                    print("SUCCESS: Data was successfully written")
                    
                    let priorBackupsCollection = playlistsCollection.document(playlist.playlist.id).collection("versionHistory")
                    
                    let priorBackupInfoEncoded = try? JSONEncoder().encode(priorBackupInfo(playlist: playlist, versionDate: Date()))
                    guard let priorBackupInfoEncoded = priorBackupInfoEncoded else { return }
                    guard let priorBackupInfoString = String(data: priorBackupInfoEncoded, encoding: .utf8) else { return }
                    
                    priorBackupsCollection.document(UUID().uuidString).setData(["data": priorBackupInfoString]) { error in
                        if let error = error {
                            print("ERROR: Error while saving version history: \(error)")
                        }
                    }
                    
                    
                    
                    continuation.resume()
                }
            }
        }
    }
    
    func uploadSpotifyAuthManager(from data: SpotifyDataModel) async throws {
        guard let user = user else {
            print("ERROR: Failed to upload data to database because the user is nil")
            throw UserError.nilUser
        }
        
        do {
            // Serialize and upload authorization_manager
            let authManagerEncoded = try JSONEncoder().encode(data.authorization_manager)
            let authDataString = String(data: authManagerEncoded, encoding: .utf8)
            
            guard let authDataString = authDataString else {
                return
            }
            
            try await firestore.collection("users")
                .document(user.uid)
                .setData(["authorization_manager": authDataString], merge: true)
            
            print("SUCCESS: Authorization manager was successfully written")
            
        } catch {
            print("ERROR: Unable to encode: \(error)")
            throw error
        }
    }
    
    func uploadSpotifyData(from data: SpotifyDataModel) async throws {
        guard let user = user else {
            print("ERROR: Failed to upload data to database because the user is nil")
            throw UserError.nilUser
        }
        
        do {
                try deleteAllPlaylists()
                // Serialize and upload authorization_manager
                let authManagerEncoded = try JSONEncoder().encode(data.authorization_manager)
                let authDataString = String(data: authManagerEncoded, encoding: .utf8)
                
                guard let authDataString = authDataString else {
                    return
                }
                
                try await firestore.collection("users")
                    .document(user.uid)
                    .setData(["authorization_manager": authDataString], merge: true)
                
                // Reference to the playlists sub-collection
                let playlistsCollection = firestore.collection("users").document(user.uid).collection("playlists")
                
                // Upload each playlist individually
                for playlist in data.playlists {
                    let playlistEncoded = try JSONEncoder().encode(playlist)
                    let playlistString = String(data: playlistEncoded, encoding: .utf8)
                    
                    guard let playlistString = playlistString else {
                        continue
                    }
                    
                    // Use playlist.id as the document ID for easier querying later
                    try await playlistsCollection.document(playlist.playlist.id)
                        .setData(["data": playlistString], merge: true)
                }
                
                print("SUCCESS: Data was successfully written")
                
            } catch {
                print("ERROR: Unable to encode: \(error)")
                throw error
            }
        
    }
    
    func deleteAllPlaylists() throws {
        guard let user = user else {
            throw UserError.nilUser
        }
        // Reference to the playlists sub-collection
        let playlistsCollection = firestore.collection("users").document(user.uid).collection("playlists")
        
        // Fetch all documents in the sub-collection
        playlistsCollection.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("ERROR: \(error)")
                return
            }
            
            // Loop through all documents and delete them
            for document in querySnapshot!.documents {
                document.reference.delete { error in
                    if let error = error {
                        print("ERROR: Failed to delete document: \(error)")
                    } else {
                        print("Document successfully deleted")
                    }
                }
            }
        }
    }
    
    func uploadUserData(from data: UserModel) async throws {
        guard let user = user else {
            print("ERROR: Failed to upload data to database because the user is nil")
            throw UserError.nilUser
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            firestore.collection("users")
                .document(user.uid)
                .setData(from: data, merge: true)
            
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            continuation.resume()
                        case .failure(let error):
                            print("ERROR: Writing data failed: \(error)")
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: {
                        print("SUCCESS: Value was successfully written")
                    }
                )
                .store(in: &cancellables)
        }
    }
}

