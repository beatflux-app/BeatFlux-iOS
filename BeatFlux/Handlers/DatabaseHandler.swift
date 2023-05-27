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
    
    func getSettingsData(completion: @escaping (SettingsDataModel?) -> Void) {
        guard let user = user else { return completion(nil) }
        

        let onErrorCompletion: ((Subscribers.Completion<Error>) -> Void) = { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error): print("ERROR: Reading data failed: \(error)")
            }
        }
        
        let onValue: (SettingsDataModel?) -> Void = { document in
            completion(document ?? SettingsDataModel(email: user.email, is_using_dark: false))
        }
        
        (db.collection("users")
            .document(user.uid)
            .getDocument(as: SettingsDataModel.self)
            .sink(receiveCompletion: onErrorCompletion, receiveValue: onValue)
            .store(in: &cancellables))
    }
}
