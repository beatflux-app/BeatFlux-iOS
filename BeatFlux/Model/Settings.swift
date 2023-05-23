//
//  Settings.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/20/23.
//

import Foundation


struct Settings: Codable {
    var user_id: String? = nil
    var email: String? = nil
    var refresh_token: String? = nil
    var is_spotify_linked: Bool = false
}
