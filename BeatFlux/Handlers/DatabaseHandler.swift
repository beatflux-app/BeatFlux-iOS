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
    
    func initializeSettings() {
        guard let user = user else { return }
        
        db.collection("users")
            .document(user.uid)
            .setData(from: SettingsDataModel(email: user.email, is_using_dark: false), merge: true)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("ERROR: Writing data failed: \(error)")
                    }
                },
                receiveValue: {
                    print("SUCCESS: Value was successfully written")
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
                    print("Document successfully updated")
                }
            }
        }
    }

    func getSettingsData() async throws -> SettingsDataModel? {
        guard let user = user else {
            print("ERROR: Failed to get settings from database because the user is nil")
            throw UserError.nilUser
        }
        return try await withCheckedThrowingContinuation { continuation in
            let docRef = db.collection("users").document(user.uid)
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    self.updateFieldIfNil(docRef: docRef, document: document, fieldName: "is_using_dark", defaultValue: SettingsDataModel.defaultData.is_using_dark)
                    self.updateFieldIfNil(docRef: docRef, document: document, fieldName: "spotify_link_shown", defaultValue: SettingsDataModel.defaultData.spotify_link_shown)
                    
                    
                    let returnValue = SettingsDataModel(
                        email: document.get("email") as? String,
                        is_using_dark: document.get("is_using_dark") as? Bool ?? SettingsDataModel.defaultData.is_using_dark,
                        spotify_link_shown: document.get("spotify_link_shown") as? Bool ?? SettingsDataModel.defaultData.spotify_link_shown)
                    
                    continuation.resume(returning: returnValue)
                } else {
                    print("Document does not exist")
                    continuation.resume(throwing: error ?? UserError.nilUser)
                }
            }
        }
    }

    
    
    func uploadSettingsData(from data: SettingsDataModel) async throws {
        guard let user = user else {
            print("ERROR: Failed to upload settings to database because the user is nil")
            throw UserError.nilUser
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("users")
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
