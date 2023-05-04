//
//  SpotifyHandler.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/3/23.
//

import Foundation
import SwiftUI

final class SpotifyAuth: ObservableObject {
    @Published var isSpotifySignedIn = false
    static let shared = SpotifyAuth()
    
    private var refreshingToken = false
    
    struct Constants {
        private static var clientID : String = ""
        private static var clientSecret: String = ""
        static let tokenAPIURL: String = "https://accounts.spotify.com/api/token"
        static let redirectURI = "https://apple.com"
        static let scopes = "user-read-private%20playlist-modify-public%20playlist-read-private%20playlist-modify-private%20user-follow-read%20user-library-modify%20user-library-read%20user-read-email"
        
        static let id_accessToken = "access_token"
        static let id_refreshToken = "refresh_token"
        static let id_expirationDate = "expiration_date"
        
        static func getClientID() -> String {
            if clientID.isEmpty {
                var nsDictionary: NSDictionary?
                if let path = Bundle.main.path(forResource: "ClientConfig", ofType: "plist") {
                    nsDictionary = NSDictionary(contentsOfFile: path)
                    if let id = nsDictionary?.value(forKey: "ClientID") {
                        clientID = id as! String
                    }
                }
            }
            
            return clientID
        }
        
        static func getClientSecret() -> String {
            if clientSecret.isEmpty {
                var nsDictionary: NSDictionary?
                if let path = Bundle.main.path(forResource: "ClientConfig", ofType: "plist") {
                    nsDictionary = NSDictionary(contentsOfFile: path)
                    if let id = nsDictionary?.value(forKey: "ClientSecret") {
                        clientSecret = id as! String
                    }
                }
            }
            
            return clientSecret
        }
        

    }
    
    private init() {
        let _accessToken = UserDefaults.standard.string(forKey: "access_token")
        self.isSpotifySignedIn = checkAccessTokenNil()
    }
    
    
    
    public var signInURL: URL? {
        let base = "https://accounts.spotify.com/authorize"
        let urlString = "\(base)?response_type=code&client_id=\(Constants.getClientID())&scope=\(Constants.scopes)&redirect_uri=\(Constants.redirectURI)&show_dialog=TRUE"
        return URL(string: urlString)
    }
    
    @AppStorage(Constants.id_accessToken) private var accessToken: String? {
        didSet{
            self.isSpotifySignedIn = checkAccessTokenNil()
        }
    }
    
    
    
    @AppStorage(Constants.id_refreshToken) private var refreshToken: String?
    @AppStorage(Constants.id_expirationDate) private var expirationDate: Date?
    
    
    private func checkAccessTokenNil() -> Bool {
        return accessToken != nil
    }
    
    private var shouldRefreshToken: Bool {
        guard let expirationDate = expirationDate else { return false }
        let currDate = Date()
        let seconds: TimeInterval = 300 // 300sec = 5min
        return currDate.addingTimeInterval(seconds) >= expirationDate
    }
    
    //allow us to get the token
    public func exchangeCodeForToken(code: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: Constants.tokenAPIURL) else {return}
       
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI)
        ]
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let basicToken = Constants.getClientID() + ":" + Constants.getClientSecret()
        let data = basicToken.data(using: .utf8)
        guard let base64String = data?.base64EncodedString() else {
            print("Err!: Failure to get base64String")
            completion(false)
            return
        }
        req.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")
        req.httpBody = components.query?.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: req) {[weak self] data, urlResponse, error in
            guard let data = data, error == nil else {
                print("Err!: data error")
                completion(false)
                return
            }
            do {
                let result = try JSONDecoder().decode(AuthenticationResponse.self, from: data)
                self?.cacheToken(result: result)
                print(result.access_token)
                
                completion(true)
            }
            catch{
                print("Err!: \(error.localizedDescription)")
                completion(false)
            }
        }
        task.resume()
    }
    
    public func cacheToken(result: AuthenticationResponse) {
        DispatchQueue.main.async {
            withAnimation {
                self.accessToken = result.access_token
                if let refresh_Token = result.refresh_token {
                    self.refreshToken = refresh_Token
                }
                self.expirationDate = Date().addingTimeInterval(TimeInterval(result.expires_in))
            }
        }
    }
    
    public func signOut(completion: (Bool) -> Void) {
        withAnimation {
            accessToken = nil
            refreshToken = nil
            expirationDate = nil
        }
        UserDefaults.standard.setValue(nil, forKey: PublicConstants.id_login_user_id)
        completion(true)
    }
    
}
