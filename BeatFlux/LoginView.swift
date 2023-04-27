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
    @Environment(\.colorScheme) var colorScheme
    
    @State var emailText = ""
    @State var passwordText = ""

    
    var body: some View {
        NavigationView {
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
                        Text("Login")
                            .font(.largeTitle)
                            .fontWeight(.bold)
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
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    } label: {
                        Rectangle()
                            .cornerRadius(16)
                            .frame(height: 50)
                            .padding(.horizontal)
                            
                            .overlay {
                                Text("Login")
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
                    
                    

                    NavigationLink(destination: SignupView().navigationBarBackButtonHidden(true)) {
                        HStack {
                            Text("Don't Have An Account? ")
                            +
                            Text("Sign Up")
                                .underline()
                        }
                        .fontWeight(.semibold)
                        .padding(.top, 5)

                    }
                    
                    Button {
                        
                    } label: {
                        
                            
                    }
                    



                    
                    Spacer()
                }
                .scrollDisabled(false)
            }
        }
        
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
