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
import SpotifyWebAPI

final class DatabaseHandler {
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    
    static let shared = DatabaseHandler()
    
    private var user: User? {
        return Auth.auth().currentUser
    }
    
    private enum UserError: Error {
        case nilUser
    }
    
    func initializeUser() {
        guard let user = user else { return }
        
        db.collection("users")
            .document(user.uid)
            .setData(from: UserModel(email: user.email, is_using_dark: false), merge: true)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("ERROR: Writing data failed: \(error)")
                    }
                },
                receiveValue: {
                    print("SUCCESS: Value was successfully initialized to database")
                }
            )
            .store(in: &cancellables)
    }
    
    
    func updateFieldIfNil<T>(docRef: DocumentReference, document: DocumentSnapshot?, fieldName: String, defaultValue: T) {
        guard let data = document?.data() else {
            print("Document data is invalid")
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
            let docRef = db.collection("users").document(user.uid)
            
            
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    self.updateFieldIfNil(docRef: docRef, document: document, fieldName: "is_using_dark", defaultValue: UserModel.defaultData.is_using_dark)
                    self.updateFieldIfNil(docRef: docRef, document: document, fieldName: "account_link_shown", defaultValue: UserModel.defaultData.account_link_shown)
                    
                    var returnValue: UserModel?

                    //MARK: NEED TO MAKE BETTER
                    
                    if let spotifyData = document.get("spotify_data") as? [String: Any], let authorizationManager = spotifyData["authorization_manager"] as? String {
                        let data = Data(authorizationManager.utf8)
                        do {
                            let decoder = JSONDecoder()
                            let authManager = try decoder.decode(AuthorizationCodeFlowManager.self, from: data)
                            
                            returnValue = UserModel(
                                email: document.get("email") as? String ?? "",
                                is_using_dark: document.get("is_using_dark") as? Bool ?? UserModel.defaultData.is_using_dark,
                                account_link_shown: document.get("account_link_shown") as? Bool ?? UserModel.defaultData.account_link_shown, spotify_data: SpotifyDataModel(authorization_manager: authManager))
                        } catch {
                            print("Error encoding AuthorizationCodeFlowManager: \(error)")
                        }
                        
                       
                    }
                    else {
                        //If no spotify data exists
                        returnValue = UserModel(
                            email: document.get("email") as? String ?? "",
                            is_using_dark: document.get("is_using_dark") as? Bool ?? UserModel.defaultData.is_using_dark,
                            account_link_shown: document.get("account_link_shown") as? Bool ?? UserModel.defaultData.account_link_shown)
                    }
                
                    
                    continuation.resume(returning: returnValue)
                } else {
                    print("Document does not exist, initlizing data (ERROR HANDLED)")
                    self.initializeUser()
                    continuation.resume(throwing: error ?? UserError.nilUser)
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
            var dictionaryToAdd: [String: Any] = [:]
            do {
                dictionaryToAdd = try data.asDictionary()
                if let spotifyData = data.spotify_data {
                    let encodedManager = try JSONEncoder().encode(spotifyData.authorization_manager)
                    let dataString = String(data: encodedManager, encoding: .utf8)
                    dictionaryToAdd.updateValue(["authorization_manager": dataString], forKey: "spotify_data")
                }
            } catch {
                print("Unable to encode")
            }
            
            db.collection("users")
                .document(user.uid)
                .setData(dictionaryToAdd)
                
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

extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
}
