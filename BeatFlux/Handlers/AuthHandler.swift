//
//  AuthHandler.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/28/23.
//

import Foundation
import FirebaseAuth
import SwiftUI


class AuthHandler: ObservableObject {

    
    enum PasswordRequirementReturnTypes {
        case success
        case needsMoreCharacters
    }
    
    @Published var isUserLoggedIn: Bool = false
    
    
    
    init() {
        Auth.auth().addStateDidChangeListener { auth, user in

            if let _ = user {
                print("Valid account")
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
        if (password != confirmPassword) { return "passwords do not match" }
        if (!isValidEmail(email)) { return "invalid email" }
        
        switch (checkRequiredPasswordParams(password: password, minCharacterCount: 6)) {
        case .needsMoreCharacters:
            return "password too short"
        default:
            break
        }
        
        
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
            return "success"
        }
        catch {
            print("USER GENERATION ERROR::\(error.localizedDescription)")
            return error.localizedDescription
        }
        
    }
    
    func loginUser(with email: String, password: String) async throws -> String {
        
        if (!isValidEmail(email)) { return "invalid email" }
        
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            return "success"
        }
        catch {
            print("USER LOGIN ERROR::\(error.localizedDescription)")
            return error.localizedDescription
        }
    }
    
    
    
    func convertStringToErrorMessage(_ errorMsg: String) -> String {
        //MARK: TODO-Add more error messages
        switch (errorMsg) {
        case "passwords do not match":
            return "Passwords do not match"
        case "invalid email":
            return "Please enter a valid email"
        case "password too short":
            return "Password is too short"
        case "The email address is already in use by another account.":
            return "Email address is already in use by another account"
        case "There is no user record corresponding to this identifier. The user may have been deleted.":
            return "Invalid Credentials"
        default:
            print(errorMsg)
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
