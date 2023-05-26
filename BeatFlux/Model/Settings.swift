//
//  Settings.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/20/23.
//

import Foundation


struct BeatFluxUserModel: Codable {
    var settings: SettingsDataModel
    var spotify_data: SpotifyDataModel?
}

struct SettingsDataModel: Codable {
    var email: String?
    var is_using_dark: Bool = false
}

struct SpotifyDataModel: Codable {
    var user_id: String?
    var refresh_token: String?
    var playlists: [SpotifyPlaylistModel]
}


struct SpotifyPlaylistModel: Codable {
    
    let added_at: String
    let added_by: AddedBy
    let is_local: Bool
    let track: SpotifyTrack

    
}

struct AddedBy: Codable {
    let external_urls: SpotifyExternalUrls
    let href: String
    let id: String
    let type: String
    let uri: String
}

struct SpotifyExternalUrls: Codable {
    let spotify: String
}



struct SpotifyAlbumImage: Codable {
    var height: Int
    var url: String
    var width: Int
}

struct SpotifyAlbum: Codable {
    let album_type: String?
    let available_markets: [String]
    let external_urls: SpotifyExternalUrls
    let href: String?
    let id: String?
    let images: [SpotifyAlbumImage]
    let name: String
    let type: String
    let uri: String?

}

struct Artist: Codable {
    let external_urls: SpotifyExternalUrls
    let href: String?
    let id: String?
    let name: String
    let type: String
    let uri: String?
}

struct SpotifyExternalIds: Codable { }

struct SpotifyTrack: Codable {
    let album: SpotifyAlbum
    let artists: [Artist]
    let available_markets: [String]
    let disc_number: Int
    let duration_ms: Int
    let explicit: Bool
    let external_ids: SpotifyExternalIds
    let external_urls: SpotifyExternalUrls
    let href: String?
    let id: String?
    let name: String
    let popularity: Int
    let preview_url: String?
    let track_number: Int
    let type: String
    let uri: String
}



/*
 {
   "added_at": "2015-01-25T07:51:45Z",
   "added_by": {
     "external_urls": {
     "spotify": "http://open.spotify.com/user/exampleuser"
   },
   "href": "https://api.spotify.com/v1/users/exampleuser",
   "id": "exampleuser",
   "type": "user",
   "uri": "spotify:user:exampleuser"
 },
 "is_local": true,
 "track": {
   [Spotify Track Object]
 }
 */

