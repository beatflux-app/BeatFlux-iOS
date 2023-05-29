//
//  BeatFluxViewModel.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/23/23.
//

import SwiftUI
import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth


class BeatFluxViewModel: ObservableObject {
    @Published var isViewModelFullyLoaded: Bool = false
    @Published var isUserLoggedIn: Bool = false {
        didSet {
            Task {
                DispatchQueue.main.async {
                    self.userData = nil
                    self.isViewModelFullyLoaded = false
                }
                if self.isUserLoggedIn {
                    await self.loadUserData()
                }
                
            }
            
            
        }
    }
    @Published var userData: UserModel? {
        didSet {
            Task {
                do {
                    if userData != nil {
                        try await uploadUserData()
                    }
                    
                } catch {
                    print("ERROR: Failed to upload user data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    enum UserError: Error {
        case nilUserData
    }
    
    private var user: User? {
        return Auth.auth().currentUser
    }
    
    init() {
        Auth.auth().addStateDidChangeListener { auth, user in
            if let _ = user {
                self.isUserLoggedIn = true
            } else {
                self.isUserLoggedIn = false
            }
        }
    }

    // Call this function once the user is signed in/up
    func loadUserData() async {
        await retrieveUserData()
        DispatchQueue.main.async {
            self.isViewModelFullyLoaded = true
        }
    }
    


    func retrieveUserData() async {
        do {
            let data = try await DatabaseHandler.shared.getUserData()
            DispatchQueue.main.async {
                self.userData = data
            }
            
        }
        catch {
            print("ERROR: Failed to retrieve user data: \(error.localizedDescription)")
        }

    }
    
    func uploadUserData() async throws {
        guard let userData = userData else {
            print("ERROR: User data is nil")
            throw UserError.nilUserData
        }
        
        do {
            try await DatabaseHandler.shared.uploadUserData(from: userData)
        }
        catch {
            print("ERROR: Failed to upload user data: \(error.localizedDescription)")
        }
            

    }
}
