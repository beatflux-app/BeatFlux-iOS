//
//  SignupView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/26/23.
//

import SwiftUI

import SwiftUI
import UIKit
import AuthenticationServices

struct SignupView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @EnvironmentObject var authHandler: AuthHandler
    
    @FocusState private var focusedField: Field?
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var error = ""
    @State private var displayAlert: Bool = false
    
    private enum Field: Hashable {
        case email
        case password
        case confirmPassword
    }
    
    var body: some View {
        VStack {
            HStack {
                Image("BeatFluxLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40)
                    .cornerRadius(16)
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .fontWeight(.bold)
                    
                }
                .padding(.leading)

            }
            .padding(.top)
            
            ScrollView {
                
                HStack {
                    Text("Sign up to get started!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding([.leading, .bottom])
                
                VStack(spacing: 25) {
                    //MARK: Email
                    AuthTextLabel_Element(text: email, placeholderText: "Email") {
                        TextField("", text: $email)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .email)
                            .onSubmit {
                                focusedField = .password
                            }
                            .onAppear {
                                focusedField = .email
                            }
                            .disabled(isLoading)
                    }
                    .padding(.horizontal)
                    
                    //MARK: Password
                    AuthTextLabel_Element(text: password, placeholderText: "Password") {
                        SecureField("", text: $password)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .password)
                            .onSubmit {
                                focusedField = .confirmPassword
                            }
                            .disabled(isLoading)
                    }
                    .padding(.horizontal)
                    
                    //MARK: Confirm Password
                    AuthTextLabel_Element(text: confirmPassword, placeholderText: "Confirm Password") {
                        SecureField("", text: $confirmPassword)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .submitLabel(.done)
                            .focused($focusedField, equals: .confirmPassword)
                            .onSubmit {
                                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                
                                authLogin()
                            }
                            .disabled(isLoading)
                    }
                    .padding(.horizontal)
                }
                
            }
            .scrollDisabled(true)
            
            
            Button {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                
                authLogin()
            } label: {
                ZStack {
                    Rectangle()
                        .cornerRadius(30)
                        .frame(height: 50)
                        .padding(.horizontal)
                        .overlay {
                            Text("Create Account")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                                .opacity(isLoading ? 0 : 1)
                    }
                    
                    LoadingIndicator(size: 45, color: .white, lineWidth: 3)
                        .opacity(isLoading ? 1 : 0)
                }
                    
            }
            .disabled(isLoading)
            .padding(.bottom)
            
            
        }
        .alert(isPresented: $displayAlert) {
                    Alert(title: Text("Cannot Create Account"), message: Text(error), dismissButton: .default(Text("Ok")))
                }
    }
    
    private func authLogin() {
        Task {
            isLoading = true
            
            do {
                let _ = try await authHandler.registerUser(with: email, password: password, confirmPassword: confirmPassword)
                beatFluxViewModel.refreshUserSettings()
            }
            catch AuthHandler.AuthResult.error(let error) {
                self.error = error
                displayAlert.toggle()
            }
            
            isLoading = false
            
        }
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
            .environmentObject(BeatFluxViewModel())
            .environmentObject(AuthHandler())
    }
}
