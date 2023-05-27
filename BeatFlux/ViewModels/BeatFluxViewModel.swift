//
//  BeatFluxViewModel.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/23/23.
//

import SwiftUI
import Foundation


class BeatFluxViewModel: ObservableObject {
    @Published var userSettings: SettingsDataModel?
    
    init() {
        refreshUserSettings()
    }
    
    
    func refreshUserSettings() {
        DatabaseHandler.shared.getSettingsData { data in
            self.userSettings = data
        }
    }
}
