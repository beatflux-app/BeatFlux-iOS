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
    
    func registerUser(with email: String, password: String, confirmPassword: String) async throws  {
        let minCharacterCount = 6
        if (password != confirmPassword) { throw AuthResult.error("Passwords do not match")}
        if (!isValidEmail(email)) { throw AuthResult.error("Please enter a valid email") }
        
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
                        DatabaseHandler.shared.initializeUser()
                        continutation.resume()
                    }
                )
                .store(in: &cancelBag)
        }
        
    }
    
    
    
    func loginUser(with email: String, password: String) async throws {
        
        if (!isValidEmail(email)) { throw AuthResult.error("Please enter a valid email") }
        
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
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailValidationRegex = "^[\\p{L}0-9!#$%&'*+\\/=?^_`{|}~-][\\p{L}0-9.!#$%&'*+\\/=?^_`{|}~-]{0,63}@[\\p{L}0-9-]+(?:\\.[\\p{L}0-9-]{2,7})*$"

          let emailValidationPredicate = NSPredicate(format: "SELF MATCHES %@", emailValidationRegex)

          return emailValidationPredicate.evaluate(with: email)
    }
}
