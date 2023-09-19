//
//  Settings.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/20/23.
//

import Foundation
import SpotifyWebAPI



struct UserModel: Codable {
    var first_name: String
    var last_name: String
    var email: String?
    var is_using_dark: Bool = false
    var account_link_shown = false
    
    static let defaultData = UserModel(first_name: "", last_name: "", email: nil, is_using_dark: false, account_link_shown: false)
}

struct SpotifyDataModel: Codable {
    var authorization_manager: AuthorizationCodeFlowManager? = nil
    var playlists: [PlaylistInfo] = []
    
    static let defaultData = SpotifyDataModel(authorization_manager: nil, playlists: [])
}


struct PlaylistInfo: Codable, Hashable {
    var playlist:Playlist<PlaylistItemsReference>
    var tracks: [PlaylistItemContainer<PlaylistItem>] = []
    var lastFetched: Date
    //var versionHistory: [priorBackupInfo] = []
}

struct priorBackupInfo: Codable, Hashable {
    var playlist: PlaylistInfo
    var versionDate: Date
}


