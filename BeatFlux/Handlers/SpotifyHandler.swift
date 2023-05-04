//
//  SpotifyHandler.swift
//  BeatFlux
//
//  Created by Ari Reitman on 5/3/23.
//

import Foundation
import Alamofire
import SwiftyJSON
import AppAuth

class SpotifyAPI {
    private let clientID = "75706410f2a24590b90d6f2e443aac42"
    private let clientSecret = "27554a67347b473f8aa875218396fcf3"
    private let redirectURI = URL(string: "https://beatflux.app/")!
    private let authorizationEndpoint = URL(string: "https://accounts.spotify.com/authorize")!
    private let tokenEndpoint = URL(string: "https://accounts.spotify.com/api/token")!
    private var accessToken: String?
    
    var authState: OIDAuthState?
    //var currentAuthorizationFlow = OIDAuthorizationFlowSession?
    
    func authenticate(completion: @escaping (Bool) -> Void) {
        let url = "https://accounts.spotify.com/api/token"
        let parameters = ["grant_type": "client_credentials"]
        let headers: HTTPHeaders = [.authorization(username: clientID, password: clientSecret)]
        
        AF.request(url, method: .post, parameters: parameters, headers: headers)
            .responseDecodable(of: AuthResponse.self) { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    self.accessToken = json["access_token"].string
                    completion(true)
                case .failure(_):
                    completion(false)
                }
            }
    }
    
//    func signIn(from presentingViewController: UIViewController, completion: @escaping (Bool) -> Void) {
//        let configuration = OIDServiceConfiguration(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint)
//        let request = OIDAuthorizationRequest(configuration: configuration, clientId: clientID, clientSecret: clientSecret, scopes: ["user-read-private", "playlist-read-private"], redirectURL: redirectURI, responseType: OIDResponseTypeCode, additionalParameters: nil)
//
//        currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: presentingViewController) { authState, error in
//            if let authState = authState {
//                self.authState = authState
//                completion(true)
//            } else {
//                completion(false)
//            }
//        }
//    }
}

struct AuthResponse: Decodable {
    let access_token: String
}

enum SpotifyAPIError: Error {
    case notAuthenticated
}
