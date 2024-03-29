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
    var is_using_dark: Bool = false
    var account_link_shown = false
    
    static let defaultData = UserModel(first_name: "", last_name: "", is_using_dark: false, account_link_shown: false)
}

struct SpotifyDataModel: Codable {
    var authorization_manager: AuthorizationCodeFlowManager? = nil
    var playlists: [PlaylistInfo] = []
    
    static let defaultData = SpotifyDataModel(authorization_manager: nil, playlists: [])
}


struct PlaylistInfo: Codable, Hashable {
    var playlist:Playlist<PlaylistItemsReference>
    var tracks: [PlaylistItemContainer<Track>] = []
    var lastFetched: Date
}

struct PlaylistSnapshot: Codable, Hashable, Identifiable {
    var id: String
    var playlist: PlaylistInfo
    var versionDate: Date
}

struct UserPlaylistCache: Codable {
    var authManager: AuthorizationCodeFlowManager?
    var lastFetched = Date()
    var playlists: [PlaylistInfo]
}
