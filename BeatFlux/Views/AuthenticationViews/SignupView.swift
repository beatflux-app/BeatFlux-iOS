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
    @ObservedObject var authHandler: AuthHandler
    
    enum Field: Hashable {
        case email
        case password
        case confirmPassword
    }
    
    @State var email = ""
    @State var password = ""
    @State var confirmPassword = ""
    @FocusState var focusedField: Field?
    
    
    @State var error = ""
    
    @State var displayAlert: Bool = false
    
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
                                //auth code
                            }
                    }
                    .padding(.horizontal)
                }
                
            }
            .scrollDisabled(true)
            
            
            Button {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                Task {
                    do {
                        let returnValue = try await authHandler.registerUser(with: email, password: password, confirmPassword: confirmPassword)
                        if (returnValue != "success") {
                            error = returnValue
                            displayAlert.toggle()
                        }
                        
                    }
                    catch {
                        
                        return
                    }
                    
                }
                
                
            } label: {
                Rectangle()
                    .cornerRadius(30)
                    .frame(height: 50)
                    .padding(.horizontal)
                    .overlay {
                        Text("Create Account")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
            }
            .padding(.bottom)
            
            
        }
        .alert(isPresented: $displayAlert) {
                    Alert(title: Text("Cannot Create Account"), message: Text(error), dismissButton: .default(Text("Ok")))
                }
        
        
        
        
        
        
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView(authHandler: AuthHandler())
    }
}
