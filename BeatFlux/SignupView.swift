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
    @Environment(\.colorScheme) var colorScheme
    
    enum Field: Hashable {
        case email
        case password
        case confirmPassword
    }
    
    @State var email = ""
    @State var password = ""
    @State var confirmPassword = ""
    @FocusState var focusedField: Field?
    
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
                    VStack {
                        ZStack(alignment: .leading) {
                            
                            
                            Text("Email")
                                .foregroundColor(email.isEmpty ? .secondary : .accentColor)
                                .offset(y: email.isEmpty ? 0 : -25)
                                .scaleEffect(email.isEmpty ? 1 : 0.8, anchor: .leading)
                            
                            
                            TextField("", text: $email)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .submitLabel(.next)
                                .focused($focusedField, equals: .email)
                                .onSubmit {
                                    focusedField = .password
                                }
                            
                            
                            
                        }
                        
                        
                        .animation(.default, value: email.isEmpty)
                        
                        Divider()
                            .frame(height: 1)
                            .padding(.horizontal, 30)
                            .background(.secondary)
                    }
                    .padding(.horizontal)
                    
                    //MARK: Password
                    VStack {
                        ZStack(alignment: .leading) {
                            
                            
                            Text("Password")
                                .foregroundColor(password.isEmpty ? .secondary : .accentColor)
                                .offset(y: password.isEmpty ? 0 : -25)
                                .scaleEffect(password.isEmpty ? 1 : 0.8, anchor: .leading)
                            
                            
                            SecureField("", text: $password)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .submitLabel(.done)
                                .focused($focusedField, equals: .password)
                                .onSubmit {
                                    focusedField = .confirmPassword
                                }
                            
                        }
                        
                        .animation(.default, value: password.isEmpty)
                        
                        Divider()
                            .frame(height: 1)
                            .padding(.horizontal, 30)
                            .background(.secondary)
                    }
                    .padding(.horizontal)
                    
                    //MARK: Confirm Password
                    VStack {
                        ZStack(alignment: .leading) {
                            
                            
                            Text("Confirm Password")
                                .foregroundColor(confirmPassword.isEmpty ? .secondary : .accentColor)
                                .offset(y: confirmPassword.isEmpty ? 0 : -25)
                                .scaleEffect(confirmPassword.isEmpty ? 1 : 0.8, anchor: .leading)
                            
                            
                            SecureField("", text: $confirmPassword)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .submitLabel(.done)
                                .focused($focusedField, equals: .confirmPassword)
                                .onSubmit {
                                    //add auth code here
                                }
                            
                        }
                        
                        .animation(.default, value: confirmPassword.isEmpty)
                        
                        Divider()
                            .frame(height: 1)
                            .padding(.horizontal, 30)
                            .background(.secondary)
                    }
                    .padding(.horizontal)
                }
                
            }
            .scrollDisabled(true)
            
            
            Button {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
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
        
        
        
        
        
        
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}
