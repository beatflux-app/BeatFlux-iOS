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
                    self.userSettings = nil
                    self.isViewModelFullyLoaded = false
                }
                if self.isUserLoggedIn {
                    await self.loadUserData()
                }
                
            }
            
            
        }
    }
    @Published var userSettings: SettingsDataModel? {
        didSet {
            Task {
                do {
                    if userSettings != nil {
                        try await uploadUserSettings()
                    }
                    
                } catch {
                    print("ERROR: Failed to upload user settings: \(error.localizedDescription)")
                }
            }
        }
    }
    
    enum UserError: Error {
        case nilUserSettings
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
        await retrieveUserSettings()
        DispatchQueue.main.async {
            self.isViewModelFullyLoaded = true
        }
    }
    


    func retrieveUserSettings() async {
        do {
            let data = try await DatabaseHandler.shared.getSettingsData()
            DispatchQueue.main.async {
                self.userSettings = data
            }
            
        }
        catch {
            print("ERROR: Failed to retrive user settings: \(error.localizedDescription)")
        }

    }
    
    func uploadUserSettings() async throws {
        guard let userSettings = userSettings else {
            print("ERROR: User settings is nil")
            throw UserError.nilUserSettings
        }
        
        do {
            try await DatabaseHandler.shared.uploadSettingsData(from: userSettings)
        }
        catch {
            print("ERROR: Failed to upload user settings: \(error.localizedDescription)")
        }
            

    }
}
