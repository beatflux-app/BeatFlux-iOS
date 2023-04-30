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
import SwiftUI


class AuthHandler: ObservableObject {

    var cancelBag = Set<AnyCancellable>()
    
    let auth = Auth.auth()
    
    
    enum PasswordRequirementReturnTypes {
        case success
        case needsMoreCharacters
    }
    
    @Published var isUserLoggedIn: Bool = false
    
    init() {
        Auth.auth().addStateDidChangeListener { auth, user in

            if let _ = user {
                self.isUserLoggedIn = true
            } else {
                self.isUserLoggedIn = false
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        }
        catch {
            print(error.localizedDescription)
        }
        
    }
    
    func registerUser(with email: String, password: String, confirmPassword: String) async throws -> String  {
        let minCharacterCount = 6
        if (password != confirmPassword) { return "Passwords do not match" }
        if (!isValidEmail(email)) { return "Please enter a valid email" }
        
        switch (checkRequiredPasswordParams(password: password, minCharacterCount: minCharacterCount)) {
        case .needsMoreCharacters:
            return "Password must be at least \(minCharacterCount) characters long"
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
                            continutation.resume(returning: errorDescription)
                        }
                        
                    },
                    receiveValue: {_ in
                        continutation.resume(returning: "success")
                    }
                )
                .store(in: &cancelBag)
        }
        
    }
    
    
    
    func loginUser(with email: String, password: String) async throws -> String {
        
        if (!isValidEmail(email)) { return "Please enter a valid email" }
        
        
        
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
                            continutation.resume(returning: errorDescription)
                        }
                        
                    },
                    receiveValue: {_ in
                        continutation.resume(returning: "success")
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
