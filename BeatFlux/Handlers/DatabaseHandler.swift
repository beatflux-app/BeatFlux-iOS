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
import FirebaseFirestoreSwift
import SpotifyWebAPI

final class DatabaseHandler {
    
    let firestore = Firestore.firestore()
    let settings = FirestoreSettings()
    let database = Firestore.firestore()
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
    
    public enum Priorities {
        case low
        case medium
        case high
    }
    
    
    init() {
        let settings = FirestoreSettings()
        settings.cacheSettings = MemoryCacheSettings()
        database.settings = settings
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
            DispatchQueue.global(qos: .background).async {
                docRef.updateData([fieldName: defaultValue]) { err in
                    if let err = err {
                        print("ERROR: Error updating document: \(err)")
                    } else {
                        print("SUCCESS: Document successfully updated")
                    }
                }
            }

        }
    }
    
    func getUserData() async throws -> UserModel? {
        guard let user = user else {
            print("ERROR: Failed to get data from database because the user is nil")
            throw UserError.nilUser
        }
        
        let docRef = firestore.collection("users").document(user.uid)
        do {
            let document = try await docRef.getDocument()
            
            if document.exists {
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
                
                return returnValue
            } else {
                print("Document does not exist, initlizing data (ERROR HANDLED)")
                self.initializeUser(firstName: UserModel.defaultData.first_name, lastName: UserModel.defaultData.last_name)
                return UserModel(first_name: UserModel.defaultData.first_name, last_name: UserModel.defaultData.last_name)
            }
        }
        catch {
            print("ERROR: Error occured when fetching user data \(error.localizedDescription)")
            throw error
        }
    }
    

    
    func getSpotifyData(source: FirestoreSource) async throws -> SpotifyDataModel {
        
                
        guard let user = self.user else {
            print("ERROR: Failed to get data from database because the user is nil")
            throw UserError.nilUser
        }
        do {
            let docRef = self.firestore.collection("users").document(user.uid)
            
            let document = try await docRef.getDocument(source: source)

            
            if document.exists {
                var spotifyData: SpotifyDataModel = SpotifyDataModel.defaultData
                let decoder = JSONDecoder()
                
                if let authorizationManager = document.get("authorization_manager") as? String {
                    do {
                        let authManager = try decoder.decode(AuthorizationCodeFlowManager.self, from: Data(authorizationManager.utf8))
                            spotifyData.authorization_manager = authManager
                        
                        
                    } catch {
                        print("ERROR: Unable to decode authorization manager \(error.localizedDescription)")
                    }
                }
                
                let playlistsCollection = self.firestore.collection("users").document(user.uid).collection("playlists")
                
                
                var playlists: [PlaylistInfo] = []
                
                let querySnapshot = try await playlistsCollection.getDocuments(source: source)

                
                for document in querySnapshot.documents {
                    if let playlist = try document.data(as: PlaylistInfo?.self) {
                        playlists.append(playlist)
                            
                        
                    }
                }
                
                spotifyData.playlists = playlists
                
                return spotifyData
                
            } else {
                print("HANDLED ERROR: Document does not exist, initializing data")
                self.initializeUser(firstName: UserModel.defaultData.first_name, lastName: UserModel.defaultData.first_name)
                throw UserError.nilUser
                
            }
        }
        catch {
            print("ERROR: Error when getting spotify data \(error.localizedDescription)")
            throw error
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
    
    func getPlaylistSnapshots(playlist: PlaylistInfo) async throws -> [PlaylistSnapshot] {
        guard let user = self.user else {
            print("ERROR: Failed to get data from database because the user is nil")
            throw UserError.nilUser
        }
        do {
            let docRef = self.firestore.collection("users").document(user.uid)
            
            let documents = try await docRef.collection("playlists").document(playlist.playlist.id).collection("snapshots").getDocuments(source: FirestoreSource.default)
            
            var snapshots: [PlaylistSnapshot] = []
            
            for document in documents.documents {
                if let decodedData = try? document.data(as: PlaylistSnapshot.self) {
                    snapshots.append(decodedData)
                }
            }
            
            return snapshots
        }
        catch {
            print("ERROR: Error while getting playlist snapshot \(error.localizedDescription)")
            return []
        }
    }
    
    func deletePlaylistSnapshot(playlistSnapshot: PlaylistSnapshot) async throws {
        guard let user = self.user else {
            print("ERROR: Failed to get data from database because the user is nil")
            throw UserError.nilUser
        }
        do {
            let docRef = self.firestore.collection("users").document(user.uid)
            
            let documents = try await docRef.collection("playlists").document(playlistSnapshot.playlist.playlist.id).collection("snapshots").getDocuments(source: FirestoreSource.default)

            
            for document in documents.documents {
                if let decodedData = try? document.data(as: PlaylistSnapshot.self) {
                    if decodedData.versionDate == playlistSnapshot.versionDate {
                        try await docRef.collection("playlists").document(playlistSnapshot.playlist.playlist.id).collection("snapshots").document(document.documentID).delete()
                    }
                }
            }
            
            print("SUCCESS: Successfully deleted playlist snapshot")

        }
        catch {
            print("ERROR: Error while deleting playlist snapshot \(error.localizedDescription)")
        }
    }
    
    func uploadPlaylistSnapshot(snapshot: PlaylistSnapshot) throws {
        guard let user = self.user else {
            print("ERROR: Failed to get upload snapshot to database because the user is nil")
            throw UserError.nilUser
        }
        
        
        let playlistsCollection = firestore.collection("users").document(user.uid).collection("playlists")
        
        let snapshotCollection = playlistsCollection.document(snapshot.playlist.playlist.id).collection("snapshots")
        
        snapshotCollection.document(UUID().uuidString).setData(from: snapshot)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main) // Switch back to the main queue for the result
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("ERROR: Error while setting playlist: \(snapshot.playlist.playlist.name): snapshot \(error.localizedDescription)")
                    return
                }
            }, receiveValue: { results in
                
                print("SUCCESS: Snapshot was successfully written")
            })
            .store(in: &cancellables)
        

        

    }
    
    func uploadSpecificFieldFromPlaylistCollection(playlist: PlaylistInfo, delete: Bool = false, source: FirestoreSource) async {
        
        guard let user = user else {
            
            print("ERROR: User does not exist")
            return
        }
        
        
        let playlistsCollection = firestore.collection("users").document(user.uid).collection("playlists")
        

        
        if delete {
            do {

                try await playlistsCollection.document(playlist.playlist.id).delete()
                
            }
            catch {
                print("ERROR: Error while deleting field from playlist collection \(error.localizedDescription)")
            }
            
        }
        else {
            
            playlistsCollection.document(playlist.playlist.id).setData(from: playlist)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main) // Switch back to the main queue for the result
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("ERROR: Error while getting users playlists \(error.localizedDescription)")
                        return
                    }
                }, receiveValue: { results in
                    
                    print("SUCCESS: Data was successfully written")
                })
                .store(in: &cancellables)

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
    
  
    func getSpotifyAuthManager() async throws -> AuthorizationCodeFlowManager? {
        guard let user = user else { throw UserError.nilUser }
        
        let docRef = self.firestore.collection("users").document(user.uid)
        let document = try await docRef.getDocument()

        
        if document.exists {
            var spotifyData: SpotifyDataModel = SpotifyDataModel.defaultData
            let decoder = JSONDecoder()
            
            if let authorizationManager = document.get("authorization_manager") as? String {
                do {
                    let authManager = try decoder.decode(AuthorizationCodeFlowManager.self, from: Data(authorizationManager.utf8))
                    spotifyData.authorization_manager = authManager
                    return authManager
                    
                    
                } catch {
                    throw error
                }
            }
        }
        
        return nil
    }
    
    
    func deleteAllPlaylists() throws {
        guard let user = user else {
            throw UserError.nilUser
        }
        // Reference to the playlists sub-collection
        let playlistsCollection = firestore.collection("users").document(user.uid).collection("playlists")
        DispatchQueue.global(qos: .background).async {
            // Fetch all documents in the sub-collection
            playlistsCollection.getDocuments() { (querySnapshot, error) in
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

