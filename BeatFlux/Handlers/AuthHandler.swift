//
//  AuthHandler.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/28/23.
//

import Foundation
import FirebaseAuth
import Combine
import CombineFirebaseAuth
import FirebaseAuth
import SwiftUI


final class AuthHandler {

    var cancelBag = Set<AnyCancellable>()
    
    private let auth = Auth.auth()
    
    static let shared = AuthHandler()
    
    enum AuthResult: Error, Equatable {
        case success
        case error(String)
    }
    
    enum PasswordRequirementReturnTypes {
        case success
        case needsMoreCharacters
    }
    
    
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        }
        catch {
            print(error.localizedDescription)
        }
        
    }
    
    func registerUser(with email: String, password: String, confirmPassword: String, firstName: String, lastName: String) async throws  {
        let minCharacterCount = 6
        if (password != confirmPassword) { throw AuthResult.error("Passwords do not match")}
        if (!email.isValidEmail()) { throw AuthResult.error("Please enter a valid email") }
        if (firstName.isEmpty) { throw AuthResult.error("Please enter a valid first name") }
        if (lastName.isEmpty) { throw AuthResult.error("Please enter a valid last name") }
        
        switch (checkRequiredPasswordParams(password: password, minCharacterCount: minCharacterCount)) {
        case .needsMoreCharacters:
            throw AuthResult.error("Password must be at least \(minCharacterCount) characters long")
        case .success:
            break
        }
        
        
        return try await withCheckedThrowingContinuation { continutation in
            auth.createUser(withEmail: email, password: password)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            print(error.localizedDescription)
                            let errorDescription = self.convertErrorToString(error)
                            continutation.resume(throwing: AuthResult.error(errorDescription))
                        }
                        
                    },
                    receiveValue: {_ in
                        DatabaseHandler.shared.initializeUser(firstName: firstName, lastName: lastName)
                        continutation.resume()
                    }
                )
                .store(in: &cancelBag)
        }
        
    }
    
    
    
    func loginUser(with email: String, password: String) async throws {
        
        if (!email.isValidEmail()) { throw AuthResult.error("Please enter a valid email") }
        
        return try await withCheckedThrowingContinuation { continutation in
            auth.signIn(withEmail: email, password: password)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            print(error.localizedDescription)
                            let errorDescription = self.convertErrorToString(error)
                            continutation.resume(throwing: AuthResult.error(errorDescription))
                        }
                        
                    },
                    receiveValue: {_ in
                        continutation.resume()
                    }
                )
                .store(in: &cancelBag)
        }
        
    }
    
    func convertErrorToString(_ error: Error) -> String {
        let nsError = error as NSError
        let authError = AuthErrorCode(_nsError: nsError)
        
        switch authError.code {
        case .wrongPassword:
            return "Invalid Credentials"
        case .emailAlreadyInUse:
            return "Email already in use"
        case .credentialAlreadyInUse:
            return "These credentials have already been used with another account"
        case .invalidEmail:
            return "Invalid Credentials"
        case .userNotFound:
            return "Invalid Credentials"
        case .userDisabled:
            return "This account has been disabled. If you have any questions, please contact info@beatflux.app"
        default:
            return "Please try again later"
        }
    }
    
    
    private func checkRequiredPasswordParams(password: String, minCharacterCount: Int) -> PasswordRequirementReturnTypes {
        if (password.count < minCharacterCount) { return .needsMoreCharacters }
        
        return .success
        
    }
    
}
