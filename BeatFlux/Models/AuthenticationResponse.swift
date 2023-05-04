//
//  Model.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/4/23.
//

import Foundation

struct AuthenticationResponse: Codable {
    let access_token: String
    let expires_in: Int
    let refresh_token: String?
    let scope: String
    let token_type: String
}
