//
//  ContentView.swift
//  BeatFlux
//
//  Created by Ari Reitman on 4/25/23.
//

import SwiftUI
import UIKit
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var beatFluxViewModel: BeatFluxViewModel
    @EnvironmentObject var authHandler: AuthHandler
    
    
    @Environment(\.dismiss) var dismiss
    
    @FocusState private var focusedField: Field?
    
    @State private var email = ""
    @State private var password = ""
    @State private var error = ""
    @State private var isLoading = false
    @State private var displayAlert: Bool = false
    
    private enum Field: Hashable {
        case email
        case password
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
                    Text("Login to your account")
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
                            .submitLabel(.done)
                            .focused($focusedField, equals: .password)
                            .onSubmit {
                                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                authLogin()
                            }
                            .disabled(isLoading)
                    }
                    .padding(.horizontal)
                }

                
                
                Spacer()
                
                
                
                
                
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
                            Text("Login")
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
                    Alert(title: Text("Cannot Login"), message: Text(error), dismissButton: .default(Text("Ok")))
                }

    }

    private func authLogin() {
        Task {
            isLoading = true
            
            do {
                let _ = try await authHandler.loginUser(with: email, password: password)
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


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(BeatFluxViewModel())
            .environmentObject(AuthHandler())
    }
}
