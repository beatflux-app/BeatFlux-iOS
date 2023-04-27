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
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State var emailText = ""
    @State var passwordText = ""
    @State var confirmPasswordText = ""
    
    var body: some View {
        VStack {
            HStack {
                Text("Sign Up")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                        
                }
                .padding(.leading)
            }
            .padding(.top)
            
            ScrollView {
                
                
                HStack {
                    
                    Spacer()
                }
                .padding(.leading)
                
                
                TextField(text: $emailText) {
                    Text("Email")
                        .padding()
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding()
                .background(Color(uiColor: .quaternarySystemFill))
                .cornerRadius(16)
                .padding(.horizontal)
                
                SecureField(text: $passwordText) {
                    Text("Password")
                        .padding()
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding()
                .background(Color(uiColor: .quaternarySystemFill))
                .cornerRadius(16)
                .padding(.horizontal)
                .padding(.top, 10)
                
                SecureField(text: $confirmPasswordText) {
                    Text("Confirm Password")
                        .padding()
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding()
                .background(Color(uiColor: .quaternarySystemFill))
                .cornerRadius(16)
                .padding(.horizontal)
                .padding(.top, 10)
                
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                } label: {
                    Rectangle()
                        .cornerRadius(16)
                        .frame(height: 50)
                        .padding(.horizontal)
                        
                        .overlay {
                            Text("Sign up")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                        .padding(.top, 10)
                    
                }
                
                HStack {
                    Rectangle()
                        .frame(height: 2)
                    Text("OR")
                    Rectangle()
                        .frame(height: 2)
                }
                .padding(.horizontal)
                .padding(.vertical, 5)
                .foregroundColor(.secondary)


                
                SignInWithAppleButton { request in
                    
                } onCompletion: { error in
                    
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .cornerRadius(16)
                .frame(height: 50)
                .padding(.horizontal)
                
                

                
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Have An Account? ")
                    +
                    Text("Login")
                        .underline()
                        
                }
                .fontWeight(.semibold)
                .padding(.top, 5)



                
                Spacer()
            }
            .scrollDisabled(false)
        }
        
        
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}
