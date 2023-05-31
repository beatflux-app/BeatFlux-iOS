//
//  Settings.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/20/23.
//

import Foundation
import SpotifyWebAPI



struct UserModel: Codable {
    var email: String?
    var is_using_dark: Bool = false
    var account_link_shown = false
    var spotify_data: SpotifyDataModel?
    
    static let defaultData = UserModel(email: nil, is_using_dark: false, account_link_shown: false)
}

struct SpotifyDataModel: Codable {
//    var user_id: String?
    var authorization_manager: AuthorizationCodeFlowManager?
    //var playlists: [Playlist<PlaylistItemsReference>]?
}
