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

final class DatabaseHandler: ObservableObject {
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    private var user: User? {
        return Auth.auth().currentUser
    }
    
    
    func intializeSettings() {
        let onErrorCompletion: ((Subscribers.Completion<Error>) -> Void) = { completion in
            switch completion {
            case .finished:
                return
            case .failure(let error): print("ERROR: Writing data failed: \(error)")
            }
        }

        let onValue: () -> Void = {
            print("SUCCCESS: Value was succesfully written")
        }
        
        
        if let user = user {
            let userDefaultSettings = Settings(user_id: user.uid, email: user.email, refresh_token: "", is_spotify_linked: false)
            
            (db.collection("users")
                .document(user.uid)
                .setData(from: userDefaultSettings, merge: true) as AnyPublisher<Void, Error>)
                    .sink(receiveCompletion: onErrorCompletion, receiveValue: onValue)
                    .store(in: &cancellables)
        }
    }
    
    public func retrieveUserSettings(_ completion: @escaping (_ success: Bool, _ data: Settings?) -> Void) async {
        
    }
    
    
}
