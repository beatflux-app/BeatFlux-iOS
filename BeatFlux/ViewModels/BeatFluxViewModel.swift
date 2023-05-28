//
//  BeatFluxViewModel.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/23/23.
//

import SwiftUI
import Foundation


class BeatFluxViewModel: ObservableObject {
    @Published var isViewModelFullyLoaded: Bool = false
    @Published var userSettings: SettingsDataModel?
    
    enum UserError: Error {
        case nilUserSettings
    }
    
    init() {
        Task {
            await retrieveUserSettings()
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
